from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..core.security import get_current_user, check_admin_role
from ..services.book_service import BookService
from ..models.books import Book, BookCreate
from ..models.users import User

router = APIRouter(
    prefix="/books",
    tags=["books"]
)

@router.get("", response_model=List[Book])
async def read_books(user: User = Depends(get_current_user)):
    return BookService.get_books()

@router.get("/{book_id}", response_model=Book)
async def read_book(book_id: int, user: User = Depends(get_current_user)):
    book = BookService.get_book(book_id)
    if book is None:
        raise HTTPException(status_code=404, detail="Book not found")
    return book

@router.post("", response_model=Book, status_code=status.HTTP_201_CREATED)
async def create_new_book(book: BookCreate, user: User = Depends(check_admin_role)):
    try:
        return BookService.create_book(book)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/{book_id}", response_model=Book)
async def update_existing_book(book_id: int, book: BookCreate, user: User = Depends(check_admin_role)):
    try:
        updated_book = BookService.update_book(book_id, book)
        if updated_book is None:
            raise HTTPException(status_code=404, detail="Book not found")
        return updated_book
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_book(book_id: int, user: User = Depends(check_admin_role)):
    success = BookService.delete_book(book_id)
    if not success:
        raise HTTPException(status_code=404, detail="Book not found")