from ..core.security import pwd_context
from ..models.users import UserInDB
from .database import db
import logging

logger = logging.getLogger(__name__)

def get_user(username: str):
    try:
        results = db.execute_query(
            "EXEC sp_GetUserByUsername @username=?",
            (username,)
        )
        return UserInDB(**results[0]) if results else None
    except Exception as e:
        logger.error(f"Error retrieving user {username}: {str(e)}")
        raise

def authenticate_user(username: str, password: str):
    from ..core.security import verify_password
    user = get_user(username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user