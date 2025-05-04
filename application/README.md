# Book Library API

A FastAPI-based RESTful API for managing a book library with authentication and role-based authorization.

## Features

- User authentication with JWT tokens
- Role-based authorization (admin and regular users)
- Book management (CRUD operations)
- Public health check endpoint
- FastAPI automatic documentation
- Docker support with health checks

## Installation

### Using pip
```bash
pip install book-library-api
```

### Using Docker
```bash
# Build and run using Docker Compose
docker compose up --build

# Or using Docker directly
docker build -t book-library-api .
docker run -p 8000:8000 book-library-api
```

## Quick Start

### Python
```python
from book_library_api import app
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Docker Environment Variables
- `SECRET_KEY`: JWT secret key (default: "your-secret-key-keep-it-secret")
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration time in minutes (default: 30)

## API Endpoints

- `GET /health` - Health check endpoint (public)
- `POST /token` - Obtain JWT token
- `GET /books` - List all books (authenticated)
- `GET /books/{book_id}` - Get book details (authenticated)
- `POST /books` - Create a new book (admin only)
- `PUT /books/{book_id}` - Update a book (admin only)
- `DELETE /books/{book_id}` - Delete a book (admin only)

## Authentication

The API uses JWT tokens for authentication. To obtain a token, send a POST request to `/token` with your credentials.

### Test Users

1. Regular User:
   - Username: johndoe
   - Password: secret123

2. Admin User:
   - Username: admin
   - Password: admin123

## Development

1. Clone the repository
2. Create a virtual environment
3. Install dependencies: `pip install -r requirements.txt`
4. Run the development server: `uvicorn src.main:app --reload`

## Docker Development

For development with Docker:

1. Clone the repository
2. Run with hot-reload: `docker compose up --build`
3. The API will be available at http://localhost:8000
4. Changes to the code will automatically reload the application

## License

MIT License