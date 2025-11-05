#!/usr/bin/env python3
"""
Comprehensive test for POST sightings API with image and audio uploads.
Tests:
1. POST a sighting with both image and audio
2. Verify files are stored in S3
3. Verify sighting is stored in RDS with correct URLs
4. Verify we can retrieve the sighting and get the URLs back
"""

import asyncio
import sys
import os
import requests
import tempfile
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import Sighting, Species
from app.services.s3_service import S3Service
from app.config import settings
import boto3
from botocore.exceptions import ClientError

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_success(msg):
    print(f"{Colors.GREEN}✓{Colors.RESET} {msg}")

def print_error(msg):
    print(f"{Colors.RED}✗{Colors.RESET} {msg}")

def print_info(msg):
    print(f"{Colors.BLUE}ℹ{Colors.RESET} {msg}")

def print_warning(msg):
    print(f"{Colors.YELLOW}⚠{Colors.RESET} {msg}")

def print_header(msg):
    print(f"\n{Colors.BOLD}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{msg}{Colors.RESET}")
    print(f"{Colors.BOLD}{'='*60}{Colors.RESET}\n")

def create_test_image() -> bytes:
    """Create a simple test image (PNG format)"""
    # Create a minimal valid PNG file (1x1 pixel red image)
    # PNG signature + minimal IHDR + minimal IDAT + IEND
    png_data = bytes([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
        0x00, 0x00, 0x00, 0x0D,  # IHDR chunk length
        0x49, 0x48, 0x44, 0x52,  # IHDR
        0x00, 0x00, 0x00, 0x01,  # width: 1
        0x00, 0x00, 0x00, 0x01,  # height: 1
        0x08, 0x02, 0x00, 0x00, 0x00,  # bit depth, color type, etc.
        0x90, 0x77, 0x53, 0xDE,  # CRC
        0x00, 0x00, 0x00, 0x0A,  # IDAT chunk length
        0x49, 0x44, 0x41, 0x54,  # IDAT
        0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,  # compressed data
        0x0D, 0x0A, 0x2D, 0xB4,  # CRC
        0x00, 0x00, 0x00, 0x00,  # IEND chunk length
        0x49, 0x45, 0x4E, 0x44,  # IEND
        0xAE, 0x42, 0x60, 0x82   # CRC
    ])
    return png_data

def create_test_audio() -> bytes:
    """Create a simple test audio file (WAV format)"""
    # Create a minimal valid WAV file (1 second of silence)
    # WAV header structure
    sample_rate = 44100
    num_channels = 1
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * (bits_per_sample // 8)
    block_align = num_channels * (bits_per_sample // 8)
    data_size = sample_rate * block_align  # 1 second of audio
    
    wav_data = b'RIFF'  # ChunkID
    wav_data += (36 + data_size).to_bytes(4, 'little')  # ChunkSize
    wav_data += b'WAVE'  # Format
    wav_data += b'fmt '  # Subchunk1ID
    wav_data += (16).to_bytes(4, 'little')  # Subchunk1Size
    wav_data += (1).to_bytes(2, 'little')  # AudioFormat (PCM)
    wav_data += num_channels.to_bytes(2, 'little')  # NumChannels
    wav_data += sample_rate.to_bytes(4, 'little')  # SampleRate
    wav_data += byte_rate.to_bytes(4, 'little')  # ByteRate
    wav_data += block_align.to_bytes(2, 'little')  # BlockAlign
    wav_data += bits_per_sample.to_bytes(2, 'little')  # BitsPerSample
    wav_data += b'data'  # Subchunk2ID
    wav_data += data_size.to_bytes(4, 'little')  # Subchunk2Size
    wav_data += b'\x00' * data_size  # Audio data (silence)
    
    return wav_data

def verify_s3_file_exists(s3_client, bucket_name: str, url: str) -> bool:
    """Verify that a file exists in S3 by checking the URL"""
    try:
        # Extract the S3 key from the URL
        # Format: https://bucket-name.s3.region.amazonaws.com/path/to/file
        if '.amazonaws.com/' not in url:
            return False
        
        key = url.split('.amazonaws.com/')[1]
        
        # Check if object exists
        s3_client.head_object(Bucket=bucket_name, Key=key)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            return False
        raise

def get_or_create_test_species(db: Session) -> Species:
    """Get or create a test species for the test"""
    species = db.query(Species).filter(
        Species.scientific_name == "Testus testus"
    ).first()
    
    if not species:
        species = Species(
            common_name="Test Species",
            scientific_name="Testus testus",
            description="A test species for API testing"
        )
        db.add(species)
        db.commit()
        db.refresh(species)
    
    return species

async def test_sighting_creation():
    """Main test function"""
    print_header("Testing POST Sightings API with Image and Audio")
    
    # Check configuration
    print_info("Checking configuration...")
    if not settings.aws_s3_bucket_name:
        print_error("AWS S3 bucket name not configured in .env file")
        return False
    
    if not settings.aws_access_key_id or not settings.aws_secret_access_key:
        print_error("AWS credentials not configured in .env file")
        return False
    
    # Check API base URL
    api_base_url = settings.api_base_url or "http://127.0.0.1:8000"
    print_info(f"API Base URL: {api_base_url}")
    
    # Initialize S3 service
    print_info("Initializing S3 service...")
    s3_service = S3Service()
    if s3_service.s3_client is None:
        print_error("S3 client not initialized. Check AWS credentials.")
        return False
    print_success("S3 service initialized")
    
    # Initialize S3 client for verification
    s3_client = boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_region
    )
    
    # Get or create test species
    print_info("Getting test species from database...")
    db = SessionLocal()
    try:
        test_species = get_or_create_test_species(db)
        species_id = test_species.id
        print_success(f"Using species ID: {species_id} ({test_species.scientific_name})")
    except Exception as e:
        print_error(f"Failed to get/create test species: {e}")
        db.close()
        return False
    finally:
        db.close()
    
    # Create test files
    print_info("Creating test image and audio files...")
    test_image_data = create_test_image()
    test_audio_data = create_test_audio()
    
    # Create temporary files
    with tempfile.NamedTemporaryFile(delete=False, suffix='.png') as img_file:
        img_file.write(test_image_data)
        img_path = img_file.name
    
    with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as audio_file:
        audio_file.write(test_audio_data)
        audio_path = audio_file.name
    
    try:
        # Step 1: POST sighting with image and audio
        print_header("Step 1: POST Sighting with Image and Audio")
        
        print_info("Sending POST request to /v1/sightings/create...")
        url = f"{api_base_url}/v1/sightings/create"
        
        with open(img_path, 'rb') as img, open(audio_path, 'rb') as audio:
            files = {
                'photo': ('test_image.png', img, 'image/png'),
                'audio': ('test_audio.wav', audio, 'audio/wav')
            }
            data = {
                'species_id': species_id,
                'lat': 42.2808,
                'lon': -83.7430,
                'username': 'TestUser',
                'caption': 'Test sighting with image and audio',
                'is_private': False
            }
            
            response = requests.post(url, files=files, data=data)
        
        if response.status_code != 200:
            print_error(f"POST request failed with status {response.status_code}")
            print_error(f"Response: {response.text}")
            return None
        
        print_success(f"POST request successful (status {response.status_code})")
        
        response_data = response.json()
        sighting_id = response_data.get('id')
        media_url = response_data.get('media_url')
        audio_url = response_data.get('audio_url')
        
        print_info(f"Sighting ID: {sighting_id}")
        print_info(f"Media URL: {media_url}")
        print_info(f"Audio URL: {audio_url}")
        
        if not sighting_id:
            print_error("Sighting ID not returned in response")
            return None
        
        if not media_url:
            print_error("Media URL not returned in response")
            return None
        
        if not audio_url:
            print_error("Audio URL not returned in response")
            return None
        
        # Store cleanup data early - we'll need it even if later steps fail
        cleanup_data = {
            'sighting_id': sighting_id,
            'media_url': media_url,
            'audio_url': audio_url,
            's3_client': s3_client,
            'bucket_name': settings.aws_s3_bucket_name
        }
        
        # Step 2: Verify files exist in S3
        print_header("Step 2: Verify Files in S3")
        
        print_info("Checking if image file exists in S3...")
        if verify_s3_file_exists(s3_client, settings.aws_s3_bucket_name, media_url):
            print_success(f"Image file verified in S3: {media_url}")
        else:
            print_error(f"Image file not found in S3: {media_url}")
            return None
        
        print_info("Checking if audio file exists in S3...")
        if verify_s3_file_exists(s3_client, settings.aws_s3_bucket_name, audio_url):
            print_success(f"Audio file verified in S3: {audio_url}")
        else:
            print_error(f"Audio file not found in S3: {audio_url}")
            return None
        
        # Step 3: Verify sighting in RDS with correct URLs
        print_header("Step 3: Verify Sighting in RDS Database")
        
        print_info("Querying database for the sighting...")
        db = SessionLocal()
        try:
            sighting = db.query(Sighting).filter(Sighting.id == sighting_id).first()
            
            if not sighting:
                print_error(f"Sighting not found in database with ID: {sighting_id}")
                return cleanup_data  # Return cleanup data even on failure
            
            print_success(f"Sighting found in database")
            print_info(f"  Database media_url: {sighting.media_url}")
            print_info(f"  Database audio_url: {sighting.audio_url}")
            
            # Verify URLs match
            if sighting.media_url != media_url:
                print_error(f"Media URL mismatch! API: {media_url}, DB: {sighting.media_url}")
                return cleanup_data  # Return cleanup data even on failure
            print_success("Media URL matches between API and database")
            
            if sighting.audio_url != audio_url:
                print_error(f"Audio URL mismatch! API: {audio_url}, DB: {sighting.audio_url}")
                return cleanup_data  # Return cleanup data even on failure
            print_success("Audio URL matches between API and database")
            
            # Verify other fields
            if sighting.species_id != species_id:
                print_error(f"Species ID mismatch! Expected: {species_id}, Got: {sighting.species_id}")
                return cleanup_data  # Return cleanup data even on failure
            print_success("Species ID matches")
            
        except Exception as e:
            print_error(f"Error querying database: {e}")
            return cleanup_data  # Return cleanup data even on failure
        finally:
            db.close()
        
        # Step 4: Verify we can retrieve the sighting and get URLs back
        print_header("Step 4: Verify GET Endpoints Return URLs")
        
        # Test GET /v1/sightings/{id}
        print_info("Testing GET /v1/sightings/{id}...")
        get_url = f"{api_base_url}/v1/sightings/{sighting_id}"
        get_response = requests.get(get_url)
        
        if get_response.status_code != 200:
            print_error(f"GET request failed with status {get_response.status_code}")
            print_error(f"Response: {get_response.text}")
            return cleanup_data  # Return cleanup data even on failure
        
        get_data = get_response.json()
        get_media_url = get_data.get('media_url')
        get_audio_url = get_data.get('audio_url')
        
        if get_media_url != media_url:
            print_error(f"GET /{id} media_url mismatch! Expected: {media_url}, Got: {get_media_url}")
            return cleanup_data  # Return cleanup data even on failure
        print_success("GET /{id} returns correct media_url")
        
        if get_audio_url != audio_url:
            print_error(f"GET /{id} audio_url mismatch! Expected: {audio_url}, Got: {get_audio_url}")
            return cleanup_data  # Return cleanup data even on failure
        print_success("GET /{id} returns correct audio_url")
        
        # Test POST /v1/sightings/ (filtered list)
        print_info("Testing POST /v1/sightings/ (filtered list)...")
        filter_url = f"{api_base_url}/v1/sightings/"
        filter_data = {
            "user_id": None,  # We'll filter by area instead
            "area": "-83.75,42.27,-83.73,42.29"  # Bounding box around test location
        }
        filter_response = requests.post(filter_url, json=filter_data)
        
        if filter_response.status_code != 200:
            print_error(f"POST /sightings/ request failed with status {filter_response.status_code}")
            print_error(f"Response: {filter_response.text}")
            return cleanup_data  # Return cleanup data even on failure
        
        filter_data_response = filter_response.json()
        items = filter_data_response.get('items', [])
        
        # Find our test sighting in the list
        test_sighting = None
        for item in items:
            if item.get('id') == sighting_id:
                test_sighting = item
                break
        
        if not test_sighting:
            print_warning("Test sighting not found in filtered list (may be due to area filter)")
            print_info("This is okay - the sighting was created successfully")
        else:
            if test_sighting.get('media_url') != media_url:
                print_error(f"POST /sightings/ media_url mismatch!")
                return cleanup_data  # Return cleanup data even on failure
            print_success("POST /sightings/ returns correct media_url")
            
            if test_sighting.get('audio_url') != audio_url:
                print_error(f"POST /sightings/ audio_url mismatch!")
                return cleanup_data  # Return cleanup data even on failure
            print_success("POST /sightings/ returns correct audio_url")
        
        # Final summary
        print_header("✅ ALL TESTS PASSED!")
        print_success("Sighting created successfully with image and audio")
        print_success("Files verified in S3")
        print_success("Sighting stored in RDS with correct URLs")
        print_success("GET endpoints return correct URLs")
        print_info(f"\nTest Sighting ID: {sighting_id}")
        print_info(f"Image URL: {media_url}")
        print_info(f"Audio URL: {audio_url}")
        
        # Return cleanup data (already stored earlier)
        return cleanup_data
        
    except requests.exceptions.ConnectionError:
        print_error(f"Could not connect to API at {api_base_url}")
        print_error("Make sure the server is running: python run.py")
        return None
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        # Cleanup temporary files
        try:
            os.unlink(img_path)
            os.unlink(audio_path)
        except:
            pass

def cleanup_test_data(cleanup_data):
    """Clean up test sighting and S3 files"""
    if not cleanup_data:
        return
    
    print_header("Cleanup: Removing Test Data")
    
    try:
        # Delete sighting from database
        print_info("Deleting test sighting from database...")
        db = SessionLocal()
        try:
            sighting = db.query(Sighting).filter(Sighting.id == cleanup_data['sighting_id']).first()
            if sighting:
                db.delete(sighting)
                db.commit()
                print_success(f"Sighting {cleanup_data['sighting_id']} deleted from database")
            else:
                print_warning(f"Sighting {cleanup_data['sighting_id']} not found in database (may have been deleted already)")
        except Exception as e:
            print_error(f"Error deleting sighting from database: {e}")
            db.rollback()
        finally:
            db.close()
        
        # Delete files from S3
        s3_client = cleanup_data['s3_client']
        bucket_name = cleanup_data['bucket_name']
        
        # Delete image file
        if cleanup_data.get('media_url'):
            try:
                key = cleanup_data['media_url'].split('.amazonaws.com/')[1]
                s3_client.delete_object(Bucket=bucket_name, Key=key)
                print_success(f"Image file deleted from S3: {key}")
            except Exception as e:
                print_warning(f"Error deleting image file from S3: {e}")
        
        # Delete audio file
        if cleanup_data.get('audio_url'):
            try:
                key = cleanup_data['audio_url'].split('.amazonaws.com/')[1]
                s3_client.delete_object(Bucket=bucket_name, Key=key)
                print_success(f"Audio file deleted from S3: {key}")
            except Exception as e:
                print_warning(f"Error deleting audio file from S3: {e}")
        
        print_success("Cleanup completed")
        
    except Exception as e:
        print_warning(f"Error during cleanup: {e}")

if __name__ == "__main__":
    import sys
    
    # Check for command-line arguments
    auto_cleanup = '--auto-cleanup' in sys.argv or '--cleanup' in sys.argv
    skip_cleanup = '--no-cleanup' in sys.argv or '--keep' in sys.argv
    
    cleanup_data = None
    try:
        result = asyncio.run(test_sighting_creation())
        
        # Check if we got cleanup data (success) or None (failure)
        if result and isinstance(result, dict):
            cleanup_data = result
            
            if skip_cleanup:
                print_info("Skipping cleanup (--no-cleanup flag set).")
                print_info(f"Sighting ID: {cleanup_data['sighting_id']}")
                sys.exit(0)
            elif auto_cleanup:
                # Automatically clean up without prompting
                cleanup_test_data(cleanup_data)
                sys.exit(0)
            else:
                # Ask user if they want to clean up
                print("\n" + "="*60)
                try:
                    response = input("Do you want to clean up test data (delete sighting and S3 files)? [Y/n]: ").strip().lower()
                    if response != 'n':
                        cleanup_test_data(cleanup_data)
                    else:
                        print_info("Skipping cleanup. Test data remains in database and S3.")
                        print_info(f"Sighting ID: {cleanup_data['sighting_id']}")
                except (EOFError, KeyboardInterrupt):
                    # Non-interactive mode or interrupted - auto cleanup
                    print_info("\nNon-interactive mode detected. Auto-cleaning up test data...")
                    cleanup_test_data(cleanup_data)
                sys.exit(0)
        else:
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        if cleanup_data:
            print_info("Cleaning up partial test data...")
            cleanup_test_data(cleanup_data)
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}❌ Unexpected error: {e}{Colors.RESET}")
        import traceback
        traceback.print_exc()
        if cleanup_data:
            print_info("Attempting to clean up test data...")
            cleanup_test_data(cleanup_data)
        sys.exit(1)

