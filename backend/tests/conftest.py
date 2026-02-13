"""
Shared fixtures for Society Financial Management API tests
"""
import pytest
import requests
import os

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

@pytest.fixture(scope="session")
def api_client():
    """Shared requests session"""
    session = requests.Session()
    session.headers.update({"Content-Type": "application/json"})
    return session

@pytest.fixture(scope="session")
def seed_data(api_client):
    """Seed demo data before tests"""
    response = api_client.post(f"{BASE_URL}/api/seed")
    assert response.status_code == 200, f"Seed failed: {response.text}"
    return response.json()

@pytest.fixture(scope="session")
def manager_auth(api_client, seed_data):
    """Get auth token for manager user (vikram@demo.com)"""
    response = api_client.post(f"{BASE_URL}/api/auth/login", json={
        "email": "vikram@demo.com",
        "password": "password123"
    })
    if response.status_code == 200:
        data = response.json()
        return {
            "token": data.get("access_token"),
            "user": data.get("user")
        }
    pytest.skip("Manager authentication failed")

@pytest.fixture(scope="session")
def member_auth(api_client, seed_data):
    """Get auth token for member user (priya@demo.com)"""
    response = api_client.post(f"{BASE_URL}/api/auth/login", json={
        "email": "priya@demo.com",
        "password": "password123"
    })
    if response.status_code == 200:
        data = response.json()
        return {
            "token": data.get("access_token"),
            "user": data.get("user")
        }
    pytest.skip("Member authentication failed")

@pytest.fixture
def manager_client(api_client, manager_auth):
    """Session with manager auth header"""
    api_client.headers.update({"Authorization": f"Bearer {manager_auth['token']}"})
    return api_client

@pytest.fixture
def member_client(api_client, member_auth):
    """Session with member auth header"""
    api_client.headers.update({"Authorization": f"Bearer {member_auth['token']}"})
    return api_client
