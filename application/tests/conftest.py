import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import pyodbc
import os
from typing import Generator
from ..src.main import app
from ..src.db.database import Database
from ..src.models.users import User

# Test database configuration
TEST_DB_SERVER = os.getenv("TEST_DB_SERVER", "localhost")
TEST_DB_NAME = os.getenv("TEST_DB_NAME", "BookLibraryDB_Test")
TEST_DB_USER = os.getenv("TEST_DB_USER", "sa")
TEST_DB_PASSWORD = os.getenv("TEST_DB_PASSWORD", "YourStrongPassword123")

@pytest.fixture(scope="session")
def test_app():
    """Create a test instance of the application."""
    return app

@pytest.fixture(scope="session")
def client(test_app) -> Generator:
    """Create a test client for the application."""
    with TestClient(test_app) as test_client:
        yield test_client

@pytest.fixture(scope="function")
def test_db():
    """Create a test database instance."""
    # Store original database connection
    original_connection = Database._connection
    
    # Create test database connection
    test_connection = pyodbc.connect(
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={TEST_DB_SERVER};'
        f'DATABASE={TEST_DB_NAME};'
        f'UID={TEST_DB_USER};'
        f'PWD={TEST_DB_PASSWORD};'
        'Trusted_Connection=no;'
    )
    
    Database._connection = test_connection
    
    yield test_connection
    
    # Restore original connection
    Database._connection = original_connection
    test_connection.close()

@pytest.fixture
def test_user():
    """Create a test user."""
    return User(
        username="testuser",
        email="test@example.com",
        full_name="Test User",
        role="user"
    )

@pytest.fixture
def test_admin():
    """Create a test admin user."""
    return User(
        username="testadmin",
        email="admin@example.com",
        full_name="Test Admin",
        role="admin"
    )

@pytest.fixture
def auth_headers(client, test_user):
    """Get authentication headers for test user."""
    response = client.post(
        "/token",
        data={
            "username": test_user.username,
            "password": "testpassword123"
        }
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}