#!/bin/bash
/opt/mssql/bin/sqlservr &

# Wait for SQL Server to be ready
sleep 30s

# Run the initialization script
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrongPassword123" -i /docker-entrypoint-initdb.d/init.sql

# Keep container running
tail -f /dev/null