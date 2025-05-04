import logging
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import HTTPException, status

from ..models.users import User, UserInDB, Token, TokenData
from ..core.security import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    SECRET_KEY,
    ALGORITHM,
    verify_password,
    get_password_hash
)
from ..db.users import get_user as db_get_user
from ..core.telemetry import create_span

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AuthService:
    @staticmethod
    def authenticate_user(username: str, password: str) -> Optional[User]:
        """Authenticate a user with username and password."""
        with create_span("authenticate_user", {"user.username": username}) as span:
            logger.info(f"Attempting to authenticate user: {username}")
            user = db_get_user(username)
            
            if not user:
                span.set_attribute("auth.success", False)
                span.set_attribute("auth.error", "user_not_found")
                logger.warning(f"User not found: {username}")
                return None
                
            if not verify_password(password, user.hashed_password):
                span.set_attribute("auth.success", False)
                span.set_attribute("auth.error", "invalid_password")
                logger.warning(f"Invalid password for user: {username}")
                return None
                
            span.set_attribute("auth.success", True)
            span.set_attribute("user.role", user.role)
            logger.info(f"Successfully authenticated user: {username}")
            return user

    @staticmethod
    def create_access_token(*, data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create a new JWT access token."""
        with create_span("create_access_token", {"user.username": data.get('sub')}) as span:
            to_encode = data.copy()
            if expires_delta:
                expire = datetime.utcnow() + expires_delta
            else:
                expire = datetime.utcnow() + timedelta(minutes=15)
                
            to_encode.update({"exp": expire})
            logger.info(f"Creating access token for user: {data.get('sub')}")
            
            try:
                encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
                span.set_attribute("token.created", True)
                logger.info(f"Successfully created access token for user: {data.get('sub')}")
                return encoded_jwt
            except Exception as e:
                span.set_attribute("token.created", False)
                span.set_attribute("error", str(e))
                logger.error(f"Error creating access token: {str(e)}")
                raise

    @staticmethod
    def verify_token(token: str) -> User:
        """Verify JWT token and return user."""
        with create_span("verify_token") as span:
            try:
                payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
                username: str = payload.get("sub")
                if username is None:
                    span.set_attribute("token.valid", False)
                    span.set_attribute("error", "missing_username")
                    logger.warning("Token missing username claim")
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Could not validate credentials",
                        headers={"WWW-Authenticate": "Bearer"},
                    )
                token_data = TokenData(username=username)
            except JWTError as e:
                span.set_attribute("token.valid", False)
                span.set_attribute("error", str(e))
                logger.error(f"JWT token verification failed: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Could not validate credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            user = db_get_user(username=token_data.username)
            if user is None:
                span.set_attribute("token.valid", False)
                span.set_attribute("error", "user_not_found")
                logger.warning(f"User not found for token: {username}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Could not validate credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            span.set_attribute("token.valid", True)
            span.set_attribute("user.username", username)
            span.set_attribute("user.role", user.role)
            logger.info(f"Successfully verified token for user: {username}")
            return user

    @staticmethod
    def get_login_response(user: User) -> Token:
        """Generate login response with access token."""
        with create_span("get_login_response", {"user.username": user.username}) as span:
            access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
            access_token = AuthService.create_access_token(
                data={"sub": user.username, "role": user.role},
                expires_delta=access_token_expires
            )
            span.set_attribute("token.expires_in_minutes", ACCESS_TOKEN_EXPIRE_MINUTES)
            return Token(access_token=access_token, token_type="bearer")