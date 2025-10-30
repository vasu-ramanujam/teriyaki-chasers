"""
Test cases for POST /api/sightings/ endpoint with image upload
Tests the functionality of creating sightings with actual image uploads.
"""
import pytest
import os
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime


class TestSightingImageUpload:
    """Test suite for POST /api/sightings/ endpoint with image upload"""
    
    @pytest.fixture
    def test_image_path(self):
        """Get the path to the test image"""
        # Get the path to the test image in the tests folder
        tests_dir = Path(__file__).parent
        image_path = tests_dir / "IMG_8867.JPG"
        
        assert image_path.exists(), f"Test image not found at {image_path}"
        return str(image_path)
    
    @pytest.fixture
    def mock_s3_service(self):
        """Mock the S3 service for testing"""
        with patch('app.routers.sightings.s3_service') as mock_service:
            # Mock the generate_presigned_upload_url method
            mock_service.generate_presigned_upload_url.return_value = (
                "https://mock-s3-upload-url.com/test",  # upload_url
                "sightings/photos/test-uuid.jpg"  # file_key
            )
            
            # Mock the get_public_url method
            mock_service.get_public_url.return_value = (
                "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
            )
            
            yield mock_service
    
    def test_create_sighting_with_photo_url(self, client, sample_species):
        """Test creating a sighting with a photo URL"""
        # Mock photo URL (simulating that the file was already uploaded to S3)
        photo_url = "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "is_private": False,
            "photo_url": photo_url,
            "notes": "Test sighting with uploaded photo"
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify sighting was created with correct data
        assert data["species_id"] == sample_species.id
        assert data["lat"] == 37.7749
        assert data["lon"] == -122.4194
        assert data["media_url"] == photo_url
        assert data["notes"] == "Test sighting with uploaded photo"
        assert data["is_private"] is False
        assert "id" in data
        assert "taken_at" in data
    
    def test_create_sighting_with_audio_url(self, client, sample_species):
        """Test creating a sighting with an audio URL"""
        # Mock audio URL (simulating that the file was already uploaded to S3)
        audio_url = "https://mock-cdn.com/sightings/audio/test-uuid.mp3"
        
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 40.7128,
            "lon": -74.0060,
            "is_private": True,
            "audio_url": audio_url,
            "notes": "Test sighting with uploaded audio"
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify sighting was created with correct data
        assert data["species_id"] == sample_species.id
        assert data["audio_url"] == audio_url
        assert data["notes"] == "Test sighting with uploaded audio"
        assert data["is_private"] is True
    
    def test_create_sighting_with_both_media_types(self, client, sample_species):
        """Test creating a sighting with both photo and audio URLs"""
        photo_url = "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        audio_url = "https://mock-cdn.com/sightings/audio/test-uuid.mp3"
        
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 34.0522,
            "lon": -118.2437,
            "is_private": False,
            "photo_url": photo_url,
            "audio_url": audio_url,
            "username": "test_user",
            "notes": "Sighting with both photo and audio"
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify sighting was created with both media types
        assert data["media_url"] == photo_url
        assert data["audio_url"] == audio_url
        assert data["username"] == "test_user"
        assert data["notes"] == "Sighting with both photo and audio"
    
    def test_create_sighting_without_media_fails(self, client, sample_species):
        """Test that creating a sighting without any media URL fails"""
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "is_private": False,
            "notes": "Sighting without media"
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        # Should fail because at least one media URL is required
        assert response.status_code == 400
        assert "media URL" in response.json()["detail"]
    
    def test_create_sighting_with_invalid_species_fails(self, client):
        """Test that creating a sighting with invalid species ID fails"""
        photo_url = "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        
        sighting_data = {
            "species_id": "invalid-species-id",
            "lat": 37.7749,
            "lon": -122.4194,
            "photo_url": photo_url
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        # Should fail because species doesn't exist
        assert response.status_code == 404
        assert "Species not found" in response.json()["detail"]
    
    def test_get_presigned_url_for_image(self, client, mock_s3_service):
        """Test getting a presigned URL for image upload"""
        request_data = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        response = client.post("/api/sightings/upload-url", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "upload_url" in data
        assert "file_key" in data
        assert "public_url" in data
        assert "expires_in" in data
        
        # Verify the URLs
        assert data["upload_url"] == "https://mock-s3-upload-url.com/test"
        assert data["file_key"] == "sightings/photos/test-uuid.jpg"
        assert data["public_url"] == "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        assert data["expires_in"] == 300
    
    def test_get_presigned_url_for_audio(self, client, mock_s3_service):
        """Test getting a presigned URL for audio upload"""
        request_data = {
            "media_type": "audio",
            "content_type": "audio/mpeg",
            "file_extension": ".mp3"
        }
        
        response = client.post("/api/sightings/upload-url", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "upload_url" in data
        assert "file_key" in data
        assert "public_url" in data
    
    def test_get_presigned_url_with_invalid_media_type(self, client, mock_s3_service):
        """Test that invalid media type is rejected"""
        request_data = {
            "media_type": "video",  # Invalid - only image and audio are supported
            "content_type": "video/mp4",
            "file_extension": ".mp4"
        }
        
        response = client.post("/api/sightings/upload-url", json=request_data)
        
        # Should fail with 400 Bad Request
        assert response.status_code == 400
        assert "media_type must be 'image' or 'audio'" in response.json()["detail"]
    
    def test_complete_upload_flow_simulation(self, client, sample_species, mock_s3_service):
        """Test the complete flow: get presigned URL, 'upload' file, create sighting"""
        
        # Step 1: Get presigned URL
        presigned_request = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        presigned_response = client.post("/api/sightings/upload-url", json=presigned_request)
        assert presigned_response.status_code == 200
        presigned_data = presigned_response.json()
        
        # Step 2: In a real scenario, client would upload to S3 using presigned URL
        # We skip this step in the test since it's mocked
        
        # Step 3: Create sighting with the public URL
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "is_private": False,
            "photo_url": presigned_data["public_url"],
            "notes": "Complete flow test"
        }
        
        sighting_response = client.post("/api/sightings/", data=sighting_data)
        assert sighting_response.status_code == 200
        sighting_data_response = sighting_response.json()
        
        # Verify the sighting was created with correct media URL
        assert sighting_data_response["media_url"] == presigned_data["public_url"]
        assert sighting_data_response["species_id"] == sample_species.id
        assert sighting_data_response["notes"] == "Complete flow test"
    
    def test_create_sighting_with_optional_username(self, client, sample_species):
        """Test creating a sighting with optional username field"""
        photo_url = "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "photo_url": photo_url,
            "username": "john_doe",
            "notes": "Spotted by John"
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "john_doe"
    
    def test_create_sighting_minimal_required_fields(self, client, sample_species):
        """Test creating a sighting with only minimal required fields"""
        photo_url = "https://mock-cdn.com/sightings/photos/test-uuid.jpg"
        
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "photo_url": photo_url
        }
        
        response = client.post("/api/sightings/", data=sighting_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify required fields
        assert data["species_id"] == sample_species.id
        assert data["lat"] == 37.7749
        assert data["lon"] == -122.4194
        assert data["media_url"] == photo_url
        
        # Verify optional fields have default/null values
        assert data["is_private"] is False  # Default value
        assert data["notes"] is None  # Optional field not provided
        assert data["username"] is None  # Optional field not provided
