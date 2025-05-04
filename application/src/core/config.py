from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional
import os
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Settings(BaseSettings):
    # API Settings
    api_title: str = os.getenv("API_TITLE", "Book Library API")
    port: int = int(os.getenv("PORT", "8000"))
    host: str = os.getenv("HOST", "0.0.0.0")
    
    # Security Settings
    secret_key: str = os.getenv("SECRET_KEY", "your-secret-key-keep-it-secret")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    
    # Database Settings
    db_server: str = os.getenv("DB_SERVER", "localhost")
    db_name: str = os.getenv("DB_NAME", "BookLibraryDB")
    db_user: str = os.getenv("DB_USER", "sa")
    db_password: str = os.getenv("DB_PASSWORD")
    db_driver: str = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
    
    # OpenTelemetry Settings
    otel_service_name: str = os.getenv("OTEL_SERVICE_NAME", "book-library-api")
    otel_collector_endpoint: str = os.getenv(
        "OTEL_COLLECTOR_ENDPOINT", 
        "http://opentelemetry-collector:4317"
    )
    otel_insecure: bool = os.getenv("OTEL_INSECURE", "true").lower() == "true"
    
    @property
    def database_url(self) -> str:
        return f"mssql+pyodbc://{self.db_user}:{self.db_password}@{self.db_server}/{self.db_name}?driver={self.db_driver.replace(' ', '+')}"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()