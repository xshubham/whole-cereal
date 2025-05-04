from typing import List, Optional
from ..models.books import Book, BookCreate
from .database import db
import logging

logger = logging.getLogger(__name__)

def get_books() -> List[Book]:
    try:
        results = db.execute_query("SELECT * FROM Books")
        return [Book(**book) for book in results]
    except Exception as e:
        logger.error(f"Error retrieving books: {str(e)}")
        raise

def get_book(book_id: int) -> Optional[Book]:
    try:
        results = db.execute_query("SELECT * FROM Books WHERE id = ?", (book_id,))
        return Book(**results[0]) if results else None
    except Exception as e:
        logger.error(f"Error retrieving book {book_id}: {str(e)}")
        raise

def create_book(book: BookCreate) -> Book:
    try:
        # Check for duplicates using stored procedure
        duplicates = db.execute_query(
            "EXEC sp_CheckBookDuplicate @title=?, @author=?",
            (book.title, book.author)
        )
        if duplicates and duplicates[0]['IsDuplicate']:
            raise ValueError("A book with this title and author already exists")

        # Insert the book
        result = db.execute_query(
            """
            INSERT INTO Books (title, author, description, published_year)
            OUTPUT INSERTED.*
            VALUES (?, ?, ?, ?)
            """,
            (book.title, book.author, book.description, book.published_year)
        )
        return Book(**result[0])
    except Exception as e:
        logger.error(f"Error creating book: {str(e)}")
        raise

def update_book(book_id: int, book: BookCreate) -> Optional[Book]:
    try:
        result = db.execute_query(
            """
            UPDATE Books
            SET title = ?, author = ?, description = ?, published_year = ?
            OUTPUT INSERTED.*
            WHERE id = ?
            """,
            (book.title, book.author, book.description, book.published_year, book_id)
        )
        return Book(**result[0]) if result else None
    except Exception as e:
        logger.error(f"Error updating book {book_id}: {str(e)}")
        raise

def delete_book(book_id: int) -> bool:
    try:
        result = db.execute_query(
            "DELETE FROM Books OUTPUT DELETED.id WHERE id = ?",
            (book_id,)
        )
        return bool(result)
    except Exception as e:
        logger.error(f"Error deleting book {book_id}: {str(e)}")
        raise