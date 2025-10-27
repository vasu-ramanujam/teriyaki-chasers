#!/usr/bin/env python3
"""
Test script for AWS S3 connection and file upload
"""

import asyncio
import sys
from app.services.s3_service import S3Service
from app.config import settings

async def test_s3_connection():
    """Test S3 service connection and upload"""
    
    print("=" * 60)
    print("AWS S3 Connection Test")
    print("=" * 60)
    print()
    
    # Check configuration
    print("1. Checking Configuration...")
    if not settings.aws_access_key_id or not settings.aws_secret_access_key:
        print("❌ ERROR: AWS credentials not configured in .env file")
        return False
    
    if not settings.aws_s3_bucket_name:
        print("❌ ERROR: AWS S3 bucket name not configured")
        return False
    
    print(f"   ✓ AWS Access Key ID: {settings.aws_access_key_id[:8]}...")
    print(f"   ✓ AWS Secret Key: {'*' * 20}...")
    print(f"   ✓ AWS Region: {settings.aws_region}")
    print(f"   ✓ S3 Bucket: {settings.aws_s3_bucket_name}")
    print()
    
    # Test S3 service
    print("2. Testing S3 Service Initialization...")
    try:
        s3_service = S3Service()
        
        if s3_service.s3_client is None:
            print("   ❌ ERROR: S3 client not initialized")
            print("   This means AWS credentials are invalid or bucket doesn't exist")
            return False
        
        print("   ✓ S3 service initialized successfully")
        print()
        
    except Exception as e:
        print(f"   ❌ ERROR initializing S3 service: {e}")
        return False
    
    # Test bucket access
    print("3. Testing Bucket Access...")
    try:
        # Try to list the bucket to verify access
        response = s3_service.s3_client.head_bucket(Bucket=settings.aws_s3_bucket_name)
        print("   ✓ Successfully connected to bucket")
        print()
    except Exception as e:
        print(f"   ❌ ERROR accessing bucket: {e}")
        print(f"   This could mean:")
        print(f"   - The bucket doesn't exist (create it in AWS Console)")
        print(f"   - Access credentials don't have permission")
        print(f"   - Wrong region specified")
        return False
    
    # Test file upload
    print("4. Testing File Upload...")
    try:
        # Create a test file
        test_content = b"This is a test file for S3 upload verification"
        test_filename = "test_upload.txt"
        
        # Upload the test file
        upload_url = await s3_service.upload_file(
            file_content=test_content,
            file_name=test_filename,
            content_type="text/plain",
            folder="test"
        )
        
        print(f"   ✓ Test file uploaded successfully!")
        print(f"   📁 URL: {upload_url}")
        print()
        
        # Try to verify the file exists
        print("5. Verifying Uploaded File...")
        try:
            response = s3_service.s3_client.head_object(
                Bucket=settings.aws_s3_bucket_name,
                Key=f"test/{test_filename}"
            )
            print(f"   ✓ File verified in S3")
            print(f"   📦 File size: {response['ContentLength']} bytes")
            print(f"   📅 Last modified: {response['LastModified']}")
            print()
        except Exception as e:
            print(f"   ⚠️  Warning: Could not verify file: {e}")
        
        # Clean up - delete test file
        print("6. Cleaning Up Test File...")
        try:
            s3_service.s3_client.delete_object(
                Bucket=settings.aws_s3_bucket_name,
                Key=f"test/{test_filename}"
            )
            print("   ✓ Test file deleted")
            print()
        except Exception as e:
            print(f"   ⚠️  Warning: Could not delete test file: {e}")
            print(f"   You can manually delete: test/{test_filename} from your bucket")
            print()
        
    except Exception as e:
        print(f"   ❌ ERROR uploading file: {e}")
        print(f"   Error details: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        return False
    
    # Final summary
    print("=" * 60)
    print("✅ ALL TESTS PASSED! S3 Configuration is Working")
    print("=" * 60)
    print()
    print("Your S3 setup is ready to use. You can now upload")
    print("images and audio files through your API!")
    print()
    
    return True

if __name__ == "__main__":
    try:
        success = asyncio.run(test_s3_connection())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

