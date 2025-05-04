from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from .routers import auth, books, health
from .core.config import get_settings
from .core.telemetry import setup_telemetry
from .db.database import db

settings = get_settings()

# Initialize telemetry before creating the FastAPI app
tracer_provider = setup_telemetry()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown events."""
    # Startup
    db.get_connection()
    
    yield
    
    # Shutdown
    if db._connection and db._connection.connected:
        db._connection.close()

app = FastAPI(title=settings.api_title, lifespan=lifespan)

# Instrument the app with OpenTelemetry after creation
FastAPIInstrumentor.instrument_app(app)

@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <!DOCTYPE html>
    <html>
        <head>
            <title>Book Library API</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    line-height: 1.6;
                }
                .endpoint {
                    background-color: #f4f4f4;
                    padding: 10px;
                    margin: 10px 0;
                    border-radius: 4px;
                }
                h1 {
                    color: #2c3e50;
                }
                a {
                    color: #3498db;
                }
            </style>
        </head>
        <body>
            <h1>Welcome to Book Library API</h1>
            <p>This is a RESTful API for managing a book library with authentication and role-based authorization.</p>
            
            <h2>Available Endpoints:</h2>
            <div class="endpoint">
                <strong>GET /health</strong> - Health check endpoint (public)
            </div>
            <div class="endpoint">
                <strong>POST /token</strong> - Obtain JWT token for authentication
            </div>
            <div class="endpoint">
                <strong>GET /books</strong> - List all books (requires authentication)
            </div>
            <div class="endpoint">
                <strong>GET /books/{id}</strong> - Get book details (requires authentication)
            </div>
            <div class="endpoint">
                <strong>POST /books</strong> - Create a new book (admin only)
            </div>
            <div class="endpoint">
                <strong>PUT /books/{id}</strong> - Update a book (admin only)
            </div>
            <div class="endpoint">
                <strong>DELETE /books/{id}</strong> - Delete a book (admin only)
            </div>
            
            <h2>Documentation</h2>
            <p>For detailed API documentation, visit:</p>
            <ul>
                <li><a href="/docs">Swagger UI documentation</a></li>
                <li><a href="/redoc">ReDoc documentation</a></li>
            </ul>
        </body>
    </html>
    """

# Include routers
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(books.router)