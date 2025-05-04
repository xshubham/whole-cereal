from pydantic import BaseModel

class Book(BaseModel):
    id: int
    title: str
    author: str
    description: str
    published_year: int

class BookCreate(BaseModel):
    title: str
    author: str
    description: str
    published_year: int