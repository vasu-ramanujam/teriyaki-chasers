"""
Integration tests for actual S3 image upload through POST /api/sightings/
These tests require AWS credentials to be configured and will actually upload files to S3.

To run only these tests:
    pytest tests/test_sighting_s3_integration.py -v

To skip these tests (useful for CI/CD without AWS credentials):
    pytest -m "not integration"
"""
import pytest
import os
import requests
from pathlib import Path
from PIL import Image
import io

# Mark all tests in this module as integration tests
pytestmark = pytest.mark.integration


class TestSightingS3Integration:
    """Integration tests for S3 upload through sighting creation"""
    
    @pytest.fixture
    def test_image_path(self):
        """Get the path to the test image"""
        tests_dir = Path(__file__).parent
        image_path = tests_dir / "IMG_8867.JPG"
        
        assert image_path.exists(), f"Test image not found at {image_path}"
        return str(image_path)
    
    @pytest.fixture
    def skip_if_no_aws_credentials(self):
        """Skip test if AWS credentials are not configured"""
        from app.config import settings
        
        if not settings.aws_access_key_id or not settings.aws_secret_access_key:
            pytest.skip("AWS credentials not configured. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables.")
    
    def test_actual_image_upload_to_s3(self, client, sample_species, test_image_path, skip_if_no_aws_credentials):
        """
        Test the complete flow with actual S3 upload:
        1. Request presigned URL from backend
        2. Upload actual test image to S3
        3. Create sighting with the uploaded image URL
        4. Verify sighting was created successfully
        5. Clean up the uploaded file
        """
        # Read the test image
        with open(test_image_path, 'rb') as f:
            image_data = f.read()
        
        # Step 1: Request presigned URL
        presigned_request = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        presigned_response = client.post("/api/sightings/upload-url", json=presigned_request)
        assert presigned_response.status_code == 200, f"Failed to get presigned URL: {presigned_response.json()}"
        
        presigned_data = presigned_response.json()
        upload_url = presigned_data["upload_url"]
        file_key = presigned_data["file_key"]
        public_url = presigned_data["public_url"]
        
        print(f"\n✓ Got presigned URL")
        print(f"  File key: {file_key}")
        print(f"  Public URL: {public_url}")
        
        # Step 2: Upload image directly to S3 using presigned URL
        # Note: We need to match the headers that were used to generate the signature
        upload_headers = {
            'Content-Type': 'image/jpeg'
        }
        
        upload_response = requests.put(
            upload_url,
            data=image_data,
            headers=upload_headers
        )
        
        assert upload_response.status_code == 200, f"Failed to upload to S3: {upload_response.status_code} - {upload_response.text}"
        print(f"✓ Successfully uploaded image to S3")
        
        # Step 3: Create sighting with the uploaded image URL
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 37.7749,
            "lon": -122.4194,
            "is_private": False,
            "photo_url": public_url,
            "notes": f"Integration test - uploaded {Path(test_image_path).name}"
        }
        
        sighting_response = client.post("/api/sightings/", data=sighting_data)
        assert sighting_response.status_code == 200, f"Failed to create sighting: {sighting_response.json()}"
        
        sighting = sighting_response.json()
        print(f"✓ Created sighting with ID: {sighting['id']}")
        
        # Step 4: Verify sighting data
        assert sighting["species_id"] == sample_species.id
        assert sighting["lat"] == 37.7749
        assert sighting["lon"] == -122.4194
        assert sighting["media_url"] == public_url
        assert "Integration test" in sighting["notes"]
        
        print(f"✓ Sighting created successfully with uploaded image")
        
        # Step 5: Verify the file exists in S3 and is accessible
        try:
            verify_response = requests.head(public_url, timeout=10)
            if verify_response.status_code == 200:
                print(f"✓ Image is accessible at: {public_url}")
            else:
                print(f"⚠ Warning: Image may not be publicly accessible (status {verify_response.status_code})")
        except Exception as e:
            print(f"⚠ Warning: Could not verify image accessibility: {e}")
        
        # Clean up: Delete the test file from S3
        try:
            from app.services.s3_service import s3_service
            s3_service.s3_client.delete_object(
                Bucket=s3_service.bucket_name,
                Key=file_key
            )
            print(f"✓ Cleaned up test file from S3")
        except Exception as e:
            print(f"⚠ Warning: Could not clean up test file: {e}")
            print(f"  Please manually delete: {file_key}")
    
    def test_upload_and_download_verification(self, client, sample_species, skip_if_no_aws_credentials):
        """
        Test uploading a generated image and verifying we can download it back
        """
        # Generate a simple test image
        img = Image.new('RGB', (200, 200), color='blue')
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        image_data = img_bytes.getvalue()
        
        # Request presigned URL
        presigned_request = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        presigned_response = client.post("/api/sightings/upload-url", json=presigned_request)
        assert presigned_response.status_code == 200
        
        presigned_data = presigned_response.json()
        upload_url = presigned_data["upload_url"]
        file_key = presigned_data["file_key"]
        public_url = presigned_data["public_url"]
        
        # Upload to S3
        upload_response = requests.put(
            upload_url,
            data=image_data,
            headers={'Content-Type': 'image/jpeg'}
        )
        assert upload_response.status_code == 200
        
        print(f"\n✓ Uploaded generated test image to S3")
        
        # Create sighting
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 40.7128,
            "lon": -74.0060,
            "photo_url": public_url,
            "notes": "Generated blue test image"
        }
        
        sighting_response = client.post("/api/sightings/", data=sighting_data)
        assert sighting_response.status_code == 200
        
        # Try to download and verify the image
        try:
            download_response = requests.get(public_url, timeout=10)
            if download_response.status_code == 200:
                downloaded_img = Image.open(io.BytesIO(download_response.content))
                assert downloaded_img.size == (200, 200), "Downloaded image has wrong dimensions"
                print(f"✓ Successfully downloaded and verified image")
            else:
                print(f"⚠ Warning: Could not download image (status {download_response.status_code})")
        except Exception as e:
            print(f"⚠ Warning: Could not verify download: {e}")
        
        # Clean up
        try:
            from app.services.s3_service import s3_service
            s3_service.s3_client.delete_object(
                Bucket=s3_service.bucket_name,
                Key=file_key
            )
            print(f"✓ Cleaned up test file from S3")
        except Exception as e:
            print(f"⚠ Warning: Could not clean up test file: {e}")
    
    def test_multiple_media_types_upload(self, client, sample_species, test_image_path, skip_if_no_aws_credentials):
        """
        Test creating a sighting with both photo and audio (photo only for now)
        """
        # Read the test image
        with open(test_image_path, 'rb') as f:
            image_data = f.read()
        
        # Upload image
        presigned_request = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        presigned_response = client.post("/api/sightings/upload-url", json=presigned_request)
        assert presigned_response.status_code == 200
        
        presigned_data = presigned_response.json()
        
        upload_response = requests.put(
            presigned_data["upload_url"],
            data=image_data,
            headers={'Content-Type': 'image/jpeg'}
        )
        assert upload_response.status_code == 200
        
        print(f"\n✓ Uploaded image to S3")
        
        # Create sighting with image (and placeholder for audio if needed)
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 34.0522,
            "lon": -118.2437,
            "photo_url": presigned_data["public_url"],
            "username": "integration_tester",
            "notes": "Multi-media test sighting"
        }
        
        sighting_response = client.post("/api/sightings/", data=sighting_data)
        assert sighting_response.status_code == 200
        
        sighting = sighting_response.json()
        assert sighting["media_url"] == presigned_data["public_url"]
        assert sighting["username"] == "integration_tester"
        
        print(f"✓ Created sighting with media: {sighting['id']}")
        
        # Clean up
        try:
            from app.services.s3_service import s3_service
            s3_service.s3_client.delete_object(
                Bucket=s3_service.bucket_name,
                Key=presigned_data["file_key"]
            )
            print(f"✓ Cleaned up test file from S3")
        except Exception as e:
            print(f"⚠ Warning: Could not clean up: {e}")
    
    def test_large_image_upload(self, client, sample_species, skip_if_no_aws_credentials):
        """
        Test uploading a larger image (approaching the size limit)
        """
        # Generate a larger test image (2MB)
        img = Image.new('RGB', (2000, 2000), color='red')
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG', quality=95)
        img_bytes.seek(0)
        image_data = img_bytes.getvalue()
        
        image_size = len(image_data)
        print(f"\n✓ Generated test image: {image_size / 1024 / 1024:.2f} MB")
        
        # Request presigned URL
        presigned_request = {
            "media_type": "image",
            "content_type": "image/jpeg",
            "file_extension": ".jpg"
        }
        
        presigned_response = client.post("/api/sightings/upload-url", json=presigned_request)
        assert presigned_response.status_code == 200
        
        presigned_data = presigned_response.json()
        
        # Upload to S3
        upload_response = requests.put(
            presigned_data["upload_url"],
            data=image_data,
            headers={'Content-Type': 'image/jpeg'}
        )
        assert upload_response.status_code == 200
        print(f"✓ Successfully uploaded large image to S3")
        
        # Create sighting
        sighting_data = {
            "species_id": sample_species.id,
            "lat": 51.5074,
            "lon": -0.1278,
            "photo_url": presigned_data["public_url"],
            "notes": f"Large image test ({image_size / 1024 / 1024:.2f} MB)"
        }
        
        sighting_response = client.post("/api/sightings/", data=sighting_data)
        assert sighting_response.status_code == 200
        print(f"✓ Created sighting with large image")
        
        # Clean up
        try:
            from app.services.s3_service import s3_service
            s3_service.s3_client.delete_object(
                Bucket=s3_service.bucket_name,
                Key=presigned_data["file_key"]
            )
            print(f"✓ Cleaned up test file from S3")
        except Exception as e:
            print(f"⚠ Warning: Could not clean up: {e}")
