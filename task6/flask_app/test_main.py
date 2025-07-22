import pytest
import json
from main import app, VERSION


@pytest.fixture
def client():
    """Create a test client for the Flask application"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_hello_world(client):
    """Test the main hello world endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    assert response.data.decode() == 'Hello, World!'


def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert data['version'] == VERSION
    assert data['service'] == 'flask-app'


def test_ready_endpoint(client):
    """Test the readiness check endpoint"""
    response = client.get('/ready')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'ready'
    assert data['version'] == VERSION
    assert data['service'] == 'flask-app'


def test_version_endpoint(client):
    """Test the version endpoint"""
    response = client.get('/version')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['version'] == VERSION
    assert data['service'] == 'flask-app'


def test_api_test_endpoint(client):
    """Test the API test endpoint"""
    response = client.get('/api/test')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['message'] == 'API is working'
    assert data['status'] == 'success'
    assert data['version'] == VERSION


def test_nonexistent_endpoint(client):
    """Test that non-existent endpoints return 404"""
    response = client.get('/nonexistent')
    assert response.status_code == 404 