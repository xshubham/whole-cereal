import pytest
from fastapi.testclient import TestClient
from src.models.books import BookCreate

class TestAPIIntegration:
    def test_health_check(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    def test_authentication_flow(self, client):
        """Test complete authentication flow."""
        # Login attempt
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        response = client.post("/token", data=login_data)
        assert response.status_code == 200
        assert "access_token" in response.json()
        assert response.json()["token_type"] == "bearer"

        # Use token to access protected endpoint
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        response = client.get("/books", headers=headers)
        assert response.status_code == 200

    def test_book_crud_operations(self, client, auth_headers):
        """Test complete CRUD operations for books."""
        # Create a new book
        new_book = {
            "title": "Integration Test Book",
            "author": "Test Author",
            "published_year": 2024,
            "genre": "Technical"
        }
        response = client.post("/books", json=new_book, headers=auth_headers)
        assert response.status_code == 201
        book_id = response.json()["id"]
        assert response.json()["title"] == new_book["title"]

        # Read the book
        response = client.get(f"/books/{book_id}", headers=auth_headers)
        assert response.status_code == 200
        assert response.json()["title"] == new_book["title"]

        # Update the book
        updated_data = {
            "title": "Updated Integration Test Book",
            "author": "Test Author",
            "published_year": 2024,
            "genre": "Technical"
        }
        response = client.put(
            f"/books/{book_id}", 
            json=updated_data,
            headers=auth_headers
        )
        assert response.status_code == 200
        assert response.json()["title"] == updated_data["title"]

        # Delete the book
        response = client.delete(f"/books/{book_id}", headers=auth_headers)
        assert response.status_code == 204

        # Verify deletion
        response = client.get(f"/books/{book_id}", headers=auth_headers)
        assert response.status_code == 404

    def test_unauthorized_access(self, client):
        """Test unauthorized access attempts."""
        # Try to access protected endpoint without token
        response = client.get("/books")
        assert response.status_code == 401

        # Try to access with invalid token
        headers = {"Authorization": "Bearer invalid_token"}
        response = client.get("/books", headers=headers)
        assert response.status_code == 401

    @pytest.mark.parametrize("invalid_book", [
        {"title": "", "author": "Test Author", "published_year": 2024},  # Empty title
        {"title": "Test Book", "author": "", "published_year": 2024},    # Empty author
        {"title": "Test Book", "author": "Test Author", "published_year": 2026},  # Future year
    ])
    def test_invalid_book_creation(self, client, auth_headers, invalid_book):
        """Test validation for book creation."""
        response = client.post("/books", json=invalid_book, headers=auth_headers)
        assert response.status_code in [400, 422]

    def test_concurrent_requests(self, client, auth_headers):
        """Test handling of concurrent requests."""
        import asyncio
        import httpx
        
        async def make_requests():
            async with httpx.AsyncClient(base_url=str(client.base_url)) as ac:
                tasks = []
                for i in range(5):
                    book = {
                        "title": f"Concurrent Book {i}",
                        "author": "Test Author",
                        "published_year": 2024,
                        "genre": "Technical"
                    }
                    tasks.append(
                        ac.post("/books", 
                               json=book, 
                               headers=auth_headers)
                    )
                responses = await asyncio.gather(*tasks)
                return responses

        responses = asyncio.run(make_requests())
        assert all(r.status_code == 201 for r in responses)
        
        # Clean up created books
        for response in responses:
            book_id = response.json()["id"]
            client.delete(f"/books/{book_id}", headers=auth_headers)