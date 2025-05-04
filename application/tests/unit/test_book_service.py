import pytest
from unittest.mock import Mock, patch
from src.services.book_service import BookService
from src.models.books import Book, BookCreate

@pytest.fixture
def mock_book():
    return Book(
        id=1,
        title="Test Book",
        author="Test Author",
        published_year=2024,
        genre="Fiction"
    )

@pytest.fixture
def mock_book_create():
    return BookCreate(
        title="New Test Book",
        author="Test Author",
        published_year=2024,
        genre="Fiction"
    )

class TestBookService:
    @patch('src.services.book_service.db_get_books')
    def test_get_books(self, mock_get_books, mock_book):
        # Arrange
        mock_get_books.return_value = [mock_book]
        
        # Act
        result = BookService.get_books()
        
        # Assert
        assert len(result) == 1
        assert result[0].title == mock_book.title
        mock_get_books.assert_called_once()

    @patch('src.services.book_service.db_get_book')
    def test_get_book(self, mock_get_book, mock_book):
        # Arrange
        mock_get_book.return_value = mock_book
        
        # Act
        result = BookService.get_book(1)
        
        # Assert
        assert result.id == mock_book.id
        assert result.title == mock_book.title
        mock_get_book.assert_called_once_with(1)

    @patch('src.services.book_service.db_get_books')
    @patch('src.services.book_service.db_create_book')
    def test_create_book(self, mock_create_book, mock_get_books, mock_book, mock_book_create):
        # Arrange
        mock_get_books.return_value = []
        mock_create_book.return_value = mock_book
        
        # Act
        result = BookService.create_book(mock_book_create)
        
        # Assert
        assert result.title == mock_book.title
        mock_create_book.assert_called_once_with(mock_book_create)

    @patch('src.services.book_service.db_get_books')
    def test_create_book_duplicate(self, mock_get_books, mock_book, mock_book_create):
        # Arrange
        mock_get_books.return_value = [mock_book]
        
        # Act & Assert
        with pytest.raises(ValueError, match="A book with this title and author already exists"):
            BookService.create_book(mock_book_create)

    @patch('src.services.book_service.db_update_book')
    def test_update_book(self, mock_update_book, mock_book, mock_book_create):
        # Arrange
        mock_update_book.return_value = mock_book
        
        # Act
        result = BookService.update_book(1, mock_book_create)
        
        # Assert
        assert result.id == mock_book.id
        mock_update_book.assert_called_once_with(1, mock_book_create)

    @patch('src.services.book_service.db_delete_book')
    def test_delete_book(self, mock_delete_book):
        # Arrange
        mock_delete_book.return_value = True
        
        # Act
        result = BookService.delete_book(1)
        
        # Assert
        assert result is True
        mock_delete_book.assert_called_once_with(1)