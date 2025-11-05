#!/usr/bin/env python3
"""
Test for GET /v1/species/{name} endpoint
Tests the merged endpoint that uses name string instead of ID and includes image
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.main import app

client = TestClient(app)

# Mock Wikipedia data for testing
MOCK_WIKI_DATA_WITH_IMAGE = {
    "english_name": "American Robin",
    "description": "The American robin is a migratory songbird of the thrush family.",
    "other_sources": [
        "https://en.wikipedia.org/wiki/American_robin",
        "https://www.wikidata.org/wiki/Q25419"
    ],
    "main_image": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/American_Robin.jpg/800px-American_Robin.jpg"
}

MOCK_WIKI_DATA_NO_IMAGE = {
    "english_name": "Test Species",
    "description": "A test species description",
    "other_sources": [
        "https://en.wikipedia.org/wiki/Test_species"
    ],
    "main_image": None
}

MOCK_WIKI_DATA_NOT_FOUND = {
    "english_name": None,
    "description": None,
    "other_sources": [],
    "main_image": None
}

class TestSpeciesByNameEndpoint:
    """Test cases for GET /v1/species/{name} endpoint"""
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_by_scientific_name(self, mock_wiki):
        """Test getting species by scientific name"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/Turdus%20migratorius")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "species" in data
        assert "english_name" in data
        assert "description" in data
        assert "other_sources" in data
        assert "main_image" in data
        
        # Verify values
        assert data["species"] == "Turdus migratorius"
        assert data["english_name"] == "American Robin"
        assert "migratory songbird" in data["description"]
        assert len(data["other_sources"]) == 2
        assert data["main_image"] is not None
        assert "wikimedia.org" in data["main_image"]
        
        # Verify Wikipedia function was called with the name
        mock_wiki.assert_called_once_with("Turdus migratorius")
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_by_common_name(self, mock_wiki):
        """Test getting species by common name"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/American%20Robin")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["species"] == "American Robin"
        assert data["english_name"] == "American Robin"
        assert data["main_image"] is not None
        
        # Verify Wikipedia function was called with the common name
        mock_wiki.assert_called_once_with("American Robin")
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_without_image(self, mock_wiki):
        """Test getting species when Wikipedia doesn't have an image"""
        mock_wiki.return_value = MOCK_WIKI_DATA_NO_IMAGE
        
        response = client.get("/v1/species/Test%20Species")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["species"] == "Test Species"
        assert data["english_name"] == "Test Species"
        assert data["main_image"] is None
        assert len(data["other_sources"]) == 1
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_not_found_in_wikipedia(self, mock_wiki):
        """Test getting species when not found in Wikipedia"""
        mock_wiki.return_value = MOCK_WIKI_DATA_NOT_FOUND
        
        response = client.get("/v1/species/Unknown%20Species")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["species"] == "Unknown Species"
        assert data["english_name"] is None
        assert data["description"] is None
        assert data["main_image"] is None
        assert data["other_sources"] == []
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_with_url_encoded_name(self, mock_wiki):
        """Test getting species with URL-encoded special characters"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        # Test with spaces encoded as %20
        response = client.get("/v1/species/Turdus%20migratorius")
        
        assert response.status_code == 200
        data = response.json()
        assert data["species"] == "Turdus migratorius"
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_with_underscores(self, mock_wiki):
        """Test getting species with underscores in name"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/Turdus_migratorius")
        
        assert response.status_code == 200
        data = response.json()
        assert data["species"] == "Turdus_migratorius"
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_response_structure(self, mock_wiki):
        """Test that response structure matches SpeciesDetails schema"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/Bird")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify all required fields are present
        required_fields = ["species", "english_name", "description", "other_sources", "main_image"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify types
        assert isinstance(data["species"], str)
        assert isinstance(data["other_sources"], list)
        assert data["english_name"] is None or isinstance(data["english_name"], str)
        assert data["description"] is None or isinstance(data["description"], str)
        assert data["main_image"] is None or isinstance(data["main_image"], str)
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_empty_name(self, mock_wiki):
        """Test getting species with empty name"""
        mock_wiki.return_value = MOCK_WIKI_DATA_NOT_FOUND
        
        response = client.get("/v1/species/")
        
        # Should return 404 or 422 (not found or method not allowed)
        assert response.status_code in [404, 405, 422]
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_with_multiple_words(self, mock_wiki):
        """Test getting species with multiple words in name"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/Red-winged%20Blackbird")
        
        assert response.status_code == 200
        data = response.json()
        assert data["species"] == "Red-winged Blackbird"
    
    @patch('app.routers.species._enrich_with_wikipedia_with_image')
    def test_get_species_image_url_format(self, mock_wiki):
        """Test that main_image URL is properly formatted when present"""
        mock_wiki.return_value = MOCK_WIKI_DATA_WITH_IMAGE
        
        response = client.get("/v1/species/Bird")
        
        assert response.status_code == 200
        data = response.json()
        
        if data["main_image"]:
            # Should be a valid URL
            assert data["main_image"].startswith("http://") or data["main_image"].startswith("https://")
            assert "." in data["main_image"]  # Should have a domain extension


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

