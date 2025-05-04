"""
Book Library API with authentication and role-based authorization
"""

from .main import app
from .models.books import Book, BookCreate
from .models.users import User, Token

__version__ = "0.1.0"
__all__ = ["app", "Book", "BookCreate", "User", "Token"]