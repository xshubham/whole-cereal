import logging
from typing import List, Optional
from ..models.books import Book, BookCreate
from ..db.books import get_books as db_get_books, get_book as db_get_book
from ..db.books import create_book as db_create_book, update_book as db_update_book
from ..db.books import delete_book as db_delete_book
from ..core.telemetry import create_span

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BookService:
    @staticmethod
    def get_books() -> List[Book]:
        """Get all books with logging and tracing."""
        with create_span("get_books") as span:
            logger.info("Retrieving all books")
            books = db_get_books()
            span.set_attribute("books.count", len(books))
            logger.info(f"Retrieved {len(books)} books")
            return books

    @staticmethod
    def get_book(book_id: int) -> Optional[Book]:
        """Get a specific book by ID with logging and tracing."""
        with create_span("get_book", {"book.id": book_id}) as span:
            logger.info(f"Retrieving book with ID: {book_id}")
            book = db_get_book(book_id)
            if book:
                span.set_attribute("book.found", True)
                span.set_attribute("book.title", book.title)
                logger.info(f"Found book: {book.title}")
            else:
                span.set_attribute("book.found", False)
                logger.warning(f"Book with ID {book_id} not found")
            return book

    @staticmethod
    def create_book(book: BookCreate) -> Book:
        """Create a new book with validation, logging, and tracing."""
        with create_span("create_book", {
            "book.title": book.title,
            "book.author": book.author
        }) as span:
            logger.info(f"Attempting to create book: {book.title}")
            
            # Check for potential duplicates
            existing_books = db_get_books()
            for existing_book in existing_books:
                if (existing_book.title.lower() == book.title.lower() and 
                    existing_book.author.lower() == book.author.lower()):
                    span.set_attribute("error", "duplicate_book")
                    logger.warning(f"Duplicate book detected: {book.title} by {book.author}")
                    raise ValueError("A book with this title and author already exists")

            # Validate publication year
            current_year = 2025  # In a real app, use datetime.now().year
            if book.published_year > current_year:
                span.set_attribute("error", "invalid_year")
                logger.error(f"Invalid publication year: {book.published_year}")
                raise ValueError("Publication year cannot be in the future")

            # Create the book
            new_book = db_create_book(book)
            span.set_attribute("book.id", new_book.id)
            logger.info(f"Successfully created book: {new_book.title} with ID: {new_book.id}")
            return new_book

    @staticmethod
    def update_book(book_id: int, book: BookCreate) -> Optional[Book]:
        """Update a book with validation, logging, and tracing."""
        with create_span("update_book", {
            "book.id": book_id,
            "book.title": book.title
        }) as span:
            logger.info(f"Attempting to update book with ID: {book_id}")

            # Validate publication year
            current_year = 2025  # In a real app, use datetime.now().year
            if book.published_year > current_year:
                span.set_attribute("error", "invalid_year")
                logger.error(f"Invalid publication year: {book.published_year}")
                raise ValueError("Publication year cannot be in the future")

            # Update the book
            updated_book = db_update_book(book_id, book)
            if updated_book:
                span.set_attribute("success", True)
                logger.info(f"Successfully updated book: {updated_book.title}")
            else:
                span.set_attribute("success", False)
                logger.warning(f"Book with ID {book_id} not found for update")
            return updated_book

    @staticmethod
    def delete_book(book_id: int) -> bool:
        """Delete a book with logging and tracing."""
        with create_span("delete_book", {"book.id": book_id}) as span:
            logger.info(f"Attempting to delete book with ID: {book_id}")
            success = db_delete_book(book_id)
            span.set_attribute("success", success)
            if success:
                logger.info(f"Successfully deleted book with ID: {book_id}")
            else:
                logger.warning(f"Book with ID {book_id} not found for deletion")
            return success