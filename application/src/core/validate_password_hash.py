from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Test password hashing
password = "secret123"
hashed = pwd_context.hash(password)
print(f"New hash: {hashed}")

# Test verification with stored hash
stored_hash = "$2b$12$ZGNZNlUzZmVhMTIzYWJjZONqf5yQn5mHOL3VwUk/0ONrRYX/qBex2"
is_valid = pwd_context.verify(password, stored_hash)
print(f"Hash verification result: {is_valid}")