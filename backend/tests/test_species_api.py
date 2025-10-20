import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.database import get_db, Base
from app.models import Species
from datetime import datetime, timezone
import httpx
from unittest.mock import patch, AsyncMock

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_species.db"
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
    """Set up test database with sample species data"""
    Base.metadata.create_all(bind=engine)
    
    # Create test species
    db = TestingSessionLocal()
    
    # Test species 1
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
    
    # Test species 2
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
    
    # Test species 3
    test_species3 = Species(
        id=3,
        common_name="Red-winged Blackbird",
        scientific_name="Agelaius phoeniceus",
        habitat="Wetlands and marshes",
        diet="Seeds and insects",
        behavior="Territorial during breeding season",
        description="A common marsh bird with distinctive red shoulder patches",
        created_at=datetime.now(timezone.utc)
    )
    
    db.add(test_species1)
    db.add(test_species2)
    db.add(test_species3)
    db.commit()
    db.close()
    
    yield
    
    # Cleanup
    Base.metadata.drop_all(bind=engine)

class TestSpeciesSearchAPI:
    """Test cases for the species search endpoint"""
    
    def test_search_species_by_common_name(self, setup_database):
        """Test searching species by common name"""
        response = client.get("/v1/species/?q=robin")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 1
        assert data["items"][0]["common_name"] == "American Robin"
        assert data["items"][0]["scientific_name"] == "Turdus migratorius"
    
    def test_search_species_by_scientific_name(self, setup_database):
        """Test searching species by scientific name"""
        response = client.get("/v1/species/?q=Turdus")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 1
        assert data["items"][0]["scientific_name"] == "Turdus migratorius"
    
    def test_search_species_case_insensitive(self, setup_database):
        """Test that search is case insensitive"""
        response = client.get("/v1/species/?q=BLUE")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 1
        assert data["items"][0]["common_name"] == "Blue Jay"
    
    def test_search_species_partial_match(self, setup_database):
        """Test searching with partial matches"""
        response = client.get("/v1/species/?q=black")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 1
        assert "blackbird" in data["items"][0]["common_name"].lower()
    
    def test_search_species_no_results(self, setup_database):
        """Test searching with no matching results"""
        response = client.get("/v1/species/?q=elephant")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) == 0
    
    def test_search_species_with_limit(self, setup_database):
        """Test searching with custom limit"""
        response = client.get("/v1/species/?q=bird&limit=2")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) <= 2
    
    def test_search_species_limit_validation(self, setup_database):
        """Test that limit parameter is properly validated"""
        # Test limit too high
        response = client.get("/v1/species/?q=bird&limit=100")
        assert response.status_code == 422
        
        # Test limit too low
        response = client.get("/v1/species/?q=bird&limit=0")
        assert response.status_code == 422
    
    def test_search_species_missing_query(self, setup_database):
        """Test search without required query parameter"""
        response = client.get("/v1/species/")
        assert response.status_code == 422

class TestSpeciesDetailAPI:
    """Test cases for the species detail endpoint"""
    
    @patch('app.routers.species._enrich_with_wikipedia')
    def test_get_species_detail_success(self, mock_wiki_enrich, setup_database):
        """Test successful retrieval of species details with Wikipedia enrichment"""
        # Mock Wikipedia enrichment response
        mock_wiki_enrich.return_value = {
            "english_name": "American Robin",
            "description": "The American robin is a migratory songbird...",
            "other_sources": [
                "https://en.wikipedia.org/wiki/American_robin",
                "https://www.wikidata.org/wiki/Q25419"
            ]
        }
        
        response = client.get("/v1/species/1")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure matches SpeciesDetails schema
        assert "species" in data
        assert "english_name" in data
        assert "description" in data
        assert "other_sources" in data
        
        # Verify specific values
        assert data["species"] == "Turdus migratorius"
        assert data["english_name"] == "American Robin"
        assert "migratory songbird" in data["description"]
        assert len(data["other_sources"]) == 2
        assert "wikipedia.org" in data["other_sources"][0]
        assert "wikidata.org" in data["other_sources"][1]
    
    @patch('app.routers.species._enrich_with_wikipedia')
    def test_get_species_detail_no_wikipedia_data(self, mock_wiki_enrich, setup_database):
        """Test species detail when Wikipedia enrichment fails"""
        # Mock Wikipedia enrichment failure
        mock_wiki_enrich.return_value = {
            "english_name": None,
            "description": None,
            "other_sources": []
        }
        
        response = client.get("/v1/species/1")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert data["species"] == "Turdus migratorius"
        assert data["english_name"] is None
        assert data["description"] is None
        assert data["other_sources"] == []
    
    def test_get_species_detail_not_found(self, setup_database):
        """Test retrieval of non-existent species ID"""
        response = client.get("/v1/species/999")
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Species not found"
    
    def test_get_species_detail_invalid_id_format(self, setup_database):
        """Test retrieval with invalid species ID format"""
        response = client.get("/v1/species/invalid-id")
        
        assert response.status_code == 422  # Validation error for non-integer ID
    
    @patch('app.routers.species._enrich_with_wikipedia')
    def test_get_species_detail_wikipedia_timeout(self, mock_wiki_enrich, setup_database):
        """Test species detail when Wikipedia API times out"""
        # Mock Wikipedia enrichment timeout/error
        mock_wiki_enrich.return_value = {
            "english_name": None,
            "description": None,
            "other_sources": []
        }
        
        response = client.get("/v1/species/2")
        
        assert response.status_code == 200
        data = response.json()
        
        # Should still return species data even if Wikipedia fails
        assert data["species"] == "Cyanocitta cristata"
        assert data["english_name"] is None
        assert data["description"] is None
        assert data["other_sources"] == []

class TestSpeciesAPIIntegration:
    """Integration tests for species API"""
    
    def test_search_then_get_detail_workflow(self, setup_database):
        """Test the common workflow of searching then getting details"""
        # First, search for a species
        search_response = client.get("/v1/species/?q=blue jay")
        assert search_response.status_code == 200
        search_data = search_response.json()
        assert len(search_data["items"]) == 1
        
        species_id = search_data["items"][0]["id"]
        
        # Then, get detailed information
        detail_response = client.get(f"/v1/species/{species_id}")
        assert detail_response.status_code == 200
        detail_data = detail_response.json()
        
        # Verify the species matches
        assert detail_data["species"] == "Cyanocitta cristata"
    
    def test_multiple_species_search(self, setup_database):
        """Test searching for multiple species"""
        response = client.get("/v1/species/?q=bird")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) >= 1  # Should find at least one bird species
        
        # Verify all results contain "bird" in common name
        for item in data["items"]:
            assert "bird" in item["common_name"].lower() or "bird" in item["scientific_name"].lower()

if __name__ == "__main__":
    pytest.main([__file__])
