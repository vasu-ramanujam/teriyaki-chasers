import pytest
import asyncio
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import get_db, Base
from app.models import Sighting, Species
from datetime import datetime, timedelta, timezone
import os

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
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
    """Set up test database with sample data"""
    Base.metadata.create_all(bind=engine)
    
    # Create test species
    db = TestingSessionLocal()
    test_species = Species(
        common_name="American Robin",
        scientific_name="Turdus migratorius",
        habitat="Woodlands and gardens",
        diet="Insects and berries",
        behavior="Migratory songbird",
        description="A common North American songbird"
    )
    db.add(test_species)
    db.flush()  # Flush to get the ID
    
    # Create test sightings
    test_sighting1 = Sighting(
        id="test-sighting-1",
        species_id=test_species.id,
        lat=42.3601,
        lon=-71.0589,
        taken_at=datetime.now(timezone.utc),
        is_private=False,
        username="testuser1",
        caption="Beautiful robin in the garden",
        media_url="test_image1.jpg"
    )
    
    test_sighting2 = Sighting(
        id="test-sighting-2", 
        species_id=test_species.id,
        lat=42.3602,
        lon=-71.0590,
        taken_at=datetime.now(timezone.utc) - timedelta(hours=1),
        is_private=True,
        username="testuser2",
        caption="Another robin sighting",
        media_url="test_image2.jpg"
    )
    
    db.add(test_sighting1)
    db.add(test_sighting2)
    db.commit()
    db.close()
    
    yield
    
    # Cleanup
    Base.metadata.drop_all(bind=engine)

class TestSightingsAPI:
    """Test cases for the sightings API endpoints"""
    
    def test_get_sightings_success(self, setup_database):
        """Test successful retrieval of sightings with filters"""
        # Get the species ID from the database
        db = TestingSessionLocal()
        species = db.query(Species).filter(Species.scientific_name == "Turdus migratorius").first()
        species_id = species.id if species else 1
        db.close()
        
        filter_data = {
            "area": "-71.07,42.35,-71.05,42.37",  # Boston area bounding box (west,south,east,north)
            "species_id": species_id,
            "start_time": (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat(),
            "end_time": datetime.now(timezone.utc).isoformat()
        }
        
        response = client.post("/v1/sightings/", json=filter_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 2  # Both test sightings should be returned
        
        # Verify sighting structure
        sighting = data["items"][0]
        assert "id" in sighting
        assert "species_id" in sighting
        assert "lat" in sighting
        assert "lon" in sighting
        assert "taken_at" in sighting
        assert "is_private" in sighting
        assert "username" in sighting
        assert "caption" in sighting
    
    def test_get_sightings_no_results(self, setup_database):
        """Test sightings query with no matching results"""
        # Get the species ID from the database
        db = TestingSessionLocal()
        species = db.query(Species).filter(Species.scientific_name == "Turdus migratorius").first()
        species_id = species.id if species else 1
        db.close()
        
        filter_data = {
            "area": "0,0,1,1",  # Different area with no sightings
            "species_id": species_id
        }
        
        response = client.post("/v1/sightings/", json=filter_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 0
    
    def test_get_sightings_invalid_area_format(self, setup_database):
        """Test sightings query with invalid area format"""
        filter_data = {
            "area": "invalid,area,format",
            "species_id": 1
        }
        
        response = client.post("/v1/sightings/", json=filter_data)
        
        assert response.status_code == 400
        assert "Invalid filter format" in response.json()["detail"]
    
    def test_get_sightings_time_filter(self, setup_database):
        """Test sightings query with time range filters"""
        # Test with start_time only - use a time in the past to include test sightings
        filter_data = {
            "area": "-71.07,42.35,-71.05,42.37",
            "start_time": (datetime.now(timezone.utc) - timedelta(hours=3)).isoformat()
        }
        
        response = client.post("/v1/sightings/", json=filter_data)
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 2  # Both test sightings should be included
    
    def test_get_sightings_species_filter(self, setup_database):
        """Test sightings query with species filter"""
        # Get the species ID from the database
        db = TestingSessionLocal()
        species = db.query(Species).filter(Species.scientific_name == "Turdus migratorius").first()
        species_id = species.id if species else 1
        db.close()
        
        filter_data = {
            "area": "-71.07,42.35,-71.05,42.37",
            "species_id": species_id
        }
        
        response = client.post("/v1/sightings/", json=filter_data)
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 2
        
        # Verify all sightings have the correct species_id
        for sighting in data["items"]:
            assert sighting["species_id"] == species_id
    
    def test_get_sighting_by_id_success(self, setup_database):
        """Test successful retrieval of a specific sighting by ID"""
        response = client.get("/v1/sightings/test-sighting-1")
        
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
        assert data["username"] == "testuser1"
        assert data["is_private"] == False
        assert data["caption"] == "Beautiful robin in the garden"
    
    def test_get_sighting_by_id_not_found(self, setup_database):
        """Test retrieval of non-existent sighting ID"""
        response = client.get("/v1/sightings/non-existent-id")
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Sighting not found"
    
    def test_get_sighting_by_id_invalid_format(self, setup_database):
        """Test retrieval with invalid sighting ID format"""
        response = client.get("/v1/sightings/")
        
        # This should return 405 Method Not Allowed since we're using GET instead of POST
        assert response.status_code == 405

class TestSightingsCreateAPI:
    """Test cases for the sighting creation endpoint"""
    
    def test_create_sighting_success(self, setup_database):
        """Test successful creation of a new sighting"""
        # Get the species ID from the database
        db = TestingSessionLocal()
        species = db.query(Species).filter(Species.scientific_name == "Turdus migratorius").first()
        species_id = species.id if species else 1
        db.close()
        
        # Create a test image file
        test_image_path = "test_image.jpg"
        with open(test_image_path, "wb") as f:
            f.write(b"fake image content")
        
        try:
            form_data = {
                "species_id": species_id,
                "lat": 42.3603,
                "lon": -71.0591,
                "is_private": False,
                "username": "newuser",
                "caption": "New sighting test"
            }
            
            with open(test_image_path, "rb") as f:
                files = {"photo": ("test_image.jpg", f, "image/jpeg")}
                response = client.post("/v1/sightings/create", data=form_data, files=files)
            
            assert response.status_code == 200
            data = response.json()
            
            # Verify response structure
            assert "id" in data
            assert data["species_id"] == species_id
            assert data["lat"] == 42.3603
            assert data["lon"] == -71.0591
            assert data["is_private"] == False
            assert data["username"] == "newuser"
            assert data["caption"] == "New sighting test"
            
        finally:
            # Cleanup test file
            if os.path.exists(test_image_path):
                os.remove(test_image_path)
    
    def test_create_sighting_species_not_found(self, setup_database):
        """Test creation of sighting with non-existent species"""
        test_image_path = "test_image.jpg"
        with open(test_image_path, "wb") as f:
            f.write(b"fake image content")
        
        try:
            form_data = {
                "species_id": 999,  # Non-existent species
                "lat": 42.3603,
                "lon": -71.0591,
                "is_private": False,
                "username": "newuser",
                "caption": "New sighting test"
            }
            
            with open(test_image_path, "rb") as f:
                files = {"photo": ("test_image.jpg", f, "image/jpeg")}
                response = client.post("/v1/sightings/create", data=form_data, files=files)
            
            assert response.status_code == 404
            assert response.json()["detail"] == "Species not found"
            
        finally:
            if os.path.exists(test_image_path):
                os.remove(test_image_path)
    
    def test_create_sighting_missing_required_fields(self, setup_database):
        """Test creation of sighting with missing required fields"""
        test_image_path = "test_image.jpg"
        with open(test_image_path, "wb") as f:
            f.write(b"fake image content")
        
        try:
            form_data = {
                "lat": 42.3603,
                "lon": -71.0591,
                # Missing species_id
            }
            
            with open(test_image_path, "rb") as f:
                files = {"photo": ("test_image.jpg", f, "image/jpeg")}
                response = client.post("/v1/sightings/create", data=form_data, files=files)
            
            assert response.status_code == 422  # Validation error
            
        finally:
            if os.path.exists(test_image_path):
                os.remove(test_image_path)

if __name__ == "__main__":
    pytest.main([__file__])