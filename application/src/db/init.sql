-- Create the database
CREATE DATABASE BookLibraryDB;
GO

USE BookLibraryDB;
GO

-- Create Users table
CREATE TABLE Users (
    username VARCHAR(100) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    disabled BIT NOT NULL DEFAULT 0,
    role VARCHAR(50) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

-- Create Books table
CREATE TABLE Books (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    author NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    published_year INT NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

-- Add unique constraint on book title and author combination
CREATE UNIQUE INDEX UX_Books_Title_Author 
ON Books(title, author);
GO

-- Create trigger for Users updated_at
CREATE TRIGGER TR_Users_UpdateTimestamp
ON Users
AFTER UPDATE
AS
BEGIN
    UPDATE Users
    SET updated_at = GETDATE()
    FROM Users u
    INNER JOIN inserted i ON u.username = i.username;
END;
GO

-- Create trigger for Books updated_at
CREATE TRIGGER TR_Books_UpdateTimestamp
ON Books
AFTER UPDATE
AS
BEGIN
    UPDATE Books
    SET updated_at = GETDATE()
    FROM Books b
    INNER JOIN inserted i ON b.id = i.id;
END;
GO

-- Insert initial users
INSERT INTO Users (username, email, full_name, hashed_password, disabled, role)
VALUES 
    ('johndoe', 'johndoe@example.com', 'John Doe', 
     -- password: secret123
     '$2b$12$BQgfWrHxpBz.Gb7JzIoFyOOhjct4G7IsG/zYEdt4cxZ9aQgVXcp5W', 
     0, 'user'),
    ('admin', 'admin@example.com', 'Admin User',
     -- password: admin123
     '$2b$12$Gu6HErKxt4MpGOedEjgkYu85CIo6IIwxS.b/8Y5jDoYk/Utiy9WUK',
     0, 'admin');
GO

-- Insert initial books
INSERT INTO Books (title, author, description, published_year)
VALUES 
    ('The Great Gatsby', 'F. Scott Fitzgerald', 'A story of the Jazz Age', 1925),
    ('1984', 'George Orwell', 'A dystopian social science fiction', 1949);
GO

-- Create stored procedure for book duplicate check
CREATE PROCEDURE sp_CheckBookDuplicate
    @title NVARCHAR(255),
    @author NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Books WHERE title = @title AND author = @author)
        SELECT 1 AS IsDuplicate;
    ELSE
        SELECT 0 AS IsDuplicate;
END;
GO

-- Create stored procedure for user authentication
CREATE PROCEDURE sp_GetUserByUsername
    @username VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT username, email, full_name, hashed_password, disabled, role
    FROM Users
    WHERE username = @username;
END;
GO