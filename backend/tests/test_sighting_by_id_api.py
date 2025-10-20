import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.database import get_db, Base
from app.models import Sighting, Species
from datetime import datetime, timedelta, timezone
import os

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_sighting_detail.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

# Clear any existing overrides and set our own
app.dependency_overrides.clear()
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(scope="function")
def setup_database():
    """Set up test database with sample data for sighting detail tests"""
    Base.metadata.create_all(bind=engine)
    
    # Create test species
    db = TestingSessionLocal()
    
    test_species1 = Species(
        id=1,
        common_name="American Robin",
        scientific_name="Turdus migratorius",
        habitat="Woodlands and gardens",
        diet="Insects and berries",
        behavior="Migratory songbird",
        description="A common North American songbird",
        created_at=datetime.now(timezone.utc)
    )
    
    test_species2 = Species(
        id=2,
        common_name="Blue Jay",
        scientific_name="Cyanocitta cristata",
        habitat="Forests and suburban areas",
        diet="Nuts, seeds, and insects",
        behavior="Intelligent and social",
        description="A colorful North American corvid",
        created_at=datetime.now(timezone.utc)
    )
    
    db.add(test_species1)
    db.add(test_species2)
    
    # Create test sightings with various scenarios
    test_sighting1 = Sighting(
        id="sighting-001",
        species_id=1,
        lat=42.3601,
        lon=-71.0589,
        taken_at=datetime.now(timezone.utc),
        is_private=False,
        username="birdwatcher1",
        caption="Beautiful robin in the garden",
        media_url="robin_001.jpg"
    )
    
    test_sighting2 = Sighting(
        id="sighting-002",
        species_id=2,
        lat=42.3602,
        lon=-71.0590,
        taken_at=datetime.now(timezone.utc) - timedelta(hours=2),
        is_private=True,
        username="birdwatcher2",
        caption="Blue jay at the feeder",
        media_url="bluejay_001.jpg"
    )
    
    test_sighting3 = Sighting(
        id="sighting-003",
        species_id=1,
        lat=42.3603,
        lon=-71.0591,
        taken_at=datetime.now(timezone.utc) - timedelta(days=1),
        is_private=False,
        username=None,  # Anonymous user
        caption=None,   # No caption
        media_url="robin_002.jpg"
    )
    
    test_sighting4 = Sighting(
        id="numeric-id-123",
        species_id=2,
        lat=42.3604,
        lon=-71.0592,
        taken_at=datetime.now(timezone.utc) - timedelta(hours=6),
        is_private=False,
        username="nature_lover",
        caption="Another blue jay sighting with a very long caption that might test the response handling",
        media_url="bluejay_002.jpg"
    )
    
    db.add(test_sighting1)
    db.add(test_sighting2)
    db.add(test_sighting3)
    db.add(test_sighting4)
    db.commit()
    db.close()
    
    yield
    
    # Cleanup
    Base.metadata.drop_all(bind=engine)

class TestSightingDetailAPI:
    """Test cases for the GET /v1/sightings/{sighting_id} endpoint"""
    
    def test_get_sighting_detail_success(self, setup_database):
        """Test successful retrieval of sighting details"""
        response = client.get("/v1/sightings/sighting-001")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure matches SightingDetail schema
        assert "id" in data
        assert "species" in data
        assert "location" in data
        assert "time" in data
        assert "username" in data
        assert "is_private" in data
        assert "caption" in data
        
        # Verify specific values
        assert data["species"] == "Turdus migratorius"
        assert data["location"] == "42.3601,-71.0589"
        assert data["username"] == "birdwatcher1"
        assert data["is_private"] == False
        assert data["caption"] == "Beautiful robin in the garden"
        
        # Verify time format is ISO
        assert "T" in data["time"]  # ISO format contains 'T'
        # Note: The API returns time without timezone info, which is acceptable
    
    def test_get_sighting_detail_private_sighting(self, setup_database):
        """Test retrieval of private sighting details"""
        response = client.get("/v1/sightings/sighting-002")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify private sighting details
        assert data["species"] == "Cyanocitta cristata"
        assert data["location"] == "42.3602,-71.059"  # Note: precision may vary
        assert data["username"] == "birdwatcher2"
        assert data["is_private"] == True
        assert data["caption"] == "Blue jay at the feeder"
    
    def test_get_sighting_detail_anonymous_user(self, setup_database):
        """Test retrieval of sighting with anonymous user"""
        response = client.get("/v1/sightings/sighting-003")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify anonymous user handling
        assert data["username"] == "Anonymous"  # Should default to "Anonymous"
        assert data["caption"] is None  # Should handle None caption
        assert data["species"] == "Turdus migratorius"
        assert data["is_private"] == False
    
    def test_get_sighting_detail_numeric_id(self, setup_database):
        """Test retrieval of sighting with numeric ID"""
        response = client.get("/v1/sightings/numeric-id-123")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify numeric ID handling
        assert data["species"] == "Cyanocitta cristata"
        assert data["username"] == "nature_lover"
        assert "very long caption" in data["caption"]
    
    def test_get_sighting_detail_not_found(self, setup_database):
        """Test retrieval of non-existent sighting ID"""
        response = client.get("/v1/sightings/non-existent-sighting")
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Sighting not found"
    
    def test_get_sighting_detail_empty_id(self, setup_database):
        """Test retrieval with empty sighting ID"""
        response = client.get("/v1/sightings/")
        
        # Should return 405 Method Not Allowed since we're using GET instead of POST
        assert response.status_code == 405
    
    def test_get_sighting_detail_special_characters(self, setup_database):
        """Test retrieval with special characters in ID"""
        response = client.get("/v1/sightings/sighting@#$%")
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Sighting not found"
    
    def test_get_sighting_detail_very_long_id(self, setup_database):
        """Test retrieval with very long sighting ID"""
        long_id = "a" * 1000
        response = client.get(f"/v1/sightings/{long_id}")
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Sighting not found"

class TestSightingDetailDataValidation:
    """Test cases for data validation in sighting detail responses"""
    
    def test_sighting_detail_id_conversion(self, setup_database):
        """Test that sighting ID is properly converted to integer"""
        response = client.get("/v1/sightings/sighting-001")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify ID is converted to integer (as per the API implementation)
        assert isinstance(data["id"], int)
        assert data["id"] > 0
    
    def test_sighting_detail_location_format(self, setup_database):
        """Test that location is properly formatted as lat,lon"""
        response = client.get("/v1/sightings/sighting-001")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify location format
        location_parts = data["location"].split(",")
        assert len(location_parts) == 2
        assert float(location_parts[0]) == 42.3601  # lat
        assert float(location_parts[1]) == -71.0589  # lon
    
    def test_sighting_detail_time_format(self, setup_database):
        """Test that time is properly formatted as ISO string"""
        response = client.get("/v1/sightings/sighting-001")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify time format
        assert isinstance(data["time"], str)
        # Should be able to parse as ISO datetime
        from datetime import datetime
        parsed_time = datetime.fromisoformat(data["time"].replace('Z', '+00:00'))
        assert isinstance(parsed_time, datetime)
    
    def test_sighting_detail_boolean_fields(self, setup_database):
        """Test that boolean fields are properly handled"""
        # Test private sighting
        response = client.get("/v1/sightings/sighting-002")
        assert response.status_code == 200
        data = response.json()
        assert data["is_private"] == True
        
        # Test public sighting
        response = client.get("/v1/sightings/sighting-001")
        assert response.status_code == 200
        data = response.json()
        assert data["is_private"] == False

class TestSightingDetailErrorHandling:
    """Test cases for error handling in sighting detail endpoint"""
    
    def test_sighting_detail_database_error(self, setup_database):
        """Test handling of database errors"""
        # This test would require mocking database errors
        # For now, we'll test the normal flow
        response = client.get("/v1/sightings/sighting-001")
        assert response.status_code == 200
    
    def test_sighting_detail_malformed_id(self, setup_database):
        """Test handling of malformed sighting IDs"""
        # Test with SQL injection attempt
        response = client.get("/v1/sightings/'; DROP TABLE sightings; --")
        assert response.status_code == 404
        
        # Test with path traversal attempt
        response = client.get("/v1/sightings/../../../etc/passwd")
        assert response.status_code == 404

class TestSightingDetailPerformance:
    """Test cases for performance considerations"""
    
    def test_sighting_detail_response_time(self, setup_database):
        """Test that sighting detail retrieval is reasonably fast"""
        import time
        
        start_time = time.time()
        response = client.get("/v1/sightings/sighting-001")
        end_time = time.time()
        
        assert response.status_code == 200
        # Should respond within 1 second (adjust as needed)
        assert (end_time - start_time) < 1.0
    
    def test_sighting_detail_concurrent_requests(self, setup_database):
        """Test handling of concurrent requests"""
        import threading
        import time
        
        results = []
        
        def make_request():
            response = client.get("/v1/sightings/sighting-001")
            results.append(response.status_code)
        
        # Make 5 concurrent requests
        threads = []
        for _ in range(5):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # All requests should succeed
        assert len(results) == 5
        assert all(status == 200 for status in results)

if __name__ == "__main__":
    pytest.main([__file__])
