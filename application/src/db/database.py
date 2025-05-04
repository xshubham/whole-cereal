import pyodbc
from typing import Optional
from ..core.config import get_settings
from ..core.telemetry import create_span
import logging

logger = logging.getLogger(__name__)

class Database:
    _instance: Optional['Database'] = None
    _connection = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Database, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if self._connection is None:
            self._connect()

    def _connect(self):
        """Establish database connection."""
        with create_span("db.connect") as span:
            settings = get_settings()
            try:
                self._connection = pyodbc.connect(
                    f'DRIVER={{{settings.db_driver}}};'
                    f'SERVER={settings.db_server};'
                    f'DATABASE={settings.db_name};'
                    f'UID={settings.db_user};'
                    f'PWD={settings.db_password};'
                    'TrustServerCertificate=yes;'
                )
                span.set_attribute("db.name", settings.db_name)
                span.set_attribute("db.server", settings.db_server)
                span.set_attribute("db.connected", True)
                logger.info("Database connection established successfully")
            except Exception as e:
                span.set_attribute("db.connected", False)
                span.set_attribute("error", str(e))
                logger.error(f"Error connecting to database: {str(e)}")
                raise

    def get_connection(self):
        """Get the database connection."""
        if not self._connection or self._connection.closed:
            self._connect()
        return self._connection

    def execute_query(self, query: str, params=None):
        """Execute a query and return results."""
        with create_span("db.execute_query") as span:
            conn = self.get_connection()
            cursor = conn.cursor()
            try:
                # Add query type attribute for monitoring
                query_type = query.strip().upper().split()[0]
                span.set_attribute("db.query_type", query_type)
                
                if params:
                    cursor.execute(query, params)
                else:
                    cursor.execute(query)
                
                if query_type in ('SELECT', 'EXEC'):
                    columns = [column[0] for column in cursor.description]
                    results = [dict(zip(columns, row)) for row in cursor.fetchall()]
                    span.set_attribute("db.rows_affected", len(results))
                    return results
                else:
                    conn.commit()
                    span.set_attribute("db.operation_success", True)
                    return None
            except Exception as e:
                span.set_attribute("db.operation_success", False)
                span.set_attribute("error", str(e))
                logger.error(f"Error executing query: {str(e)}")
                conn.rollback()
                raise
            finally:
                cursor.close()

# Create a global instance
db = Database()