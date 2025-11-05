#!/usr/bin/env python3
"""
Script to check if the S3 bucket exists in AWS
"""

import boto3
from botocore.exceptions import ClientError
from app.config import settings

def check_bucket_exists():
    """Check if the S3 bucket exists and is accessible"""
    
    print("=" * 60)
    print("AWS S3 Bucket Existence Check")
    print("=" * 60)
    print()
    
    # Check configuration
    if not settings.aws_access_key_id or not settings.aws_secret_access_key:
        print("❌ ERROR: AWS credentials not configured")
        print("Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env file")
        return False
    
    if not settings.aws_s3_bucket_name:
        print("❌ ERROR: AWS S3 bucket name not configured")
        print("Please set AWS_S3_BUCKET_NAME in .env file")
        return False
    
    print(f"Bucket Name: {settings.aws_s3_bucket_name}")
    print(f"Region: {settings.aws_region}")
    print(f"Access Key ID: {settings.aws_access_key_id[:8]}...")
    print()
    
    # Initialize S3 client
    try:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_region
        )
    except Exception as e:
        print(f"❌ ERROR: Failed to initialize S3 client: {e}")
        return False
    
    # Check if bucket exists using head_bucket
    print("Checking bucket existence...")
    try:
        response = s3_client.head_bucket(Bucket=settings.aws_s3_bucket_name)
        print(f"✅ SUCCESS: Bucket '{settings.aws_s3_bucket_name}' EXISTS and is accessible!")
        print()
        
        # Get additional bucket info
        try:
            location = s3_client.get_bucket_location(Bucket=settings.aws_s3_bucket_name)
            region = location.get('LocationConstraint') or 'us-east-1'  # us-east-1 returns None
            print(f"📍 Bucket Location: {region}")
            
            # Try to get bucket metadata
            try:
                # List some objects to verify read access
                response = s3_client.list_objects_v2(
                    Bucket=settings.aws_s3_bucket_name,
                    MaxKeys=5
                )
                object_count = response.get('KeyCount', 0)
                if 'Contents' in response:
                    print(f"📦 Objects in bucket: {object_count} (showing first 5)")
                    for obj in response.get('Contents', [])[:5]:
                        print(f"   - {obj['Key']} ({obj['Size']} bytes, modified: {obj['LastModified']})")
                else:
                    print(f"📦 Bucket is empty (no objects found)")
            except ClientError as e:
                error_code = e.response.get('Error', {}).get('Code', 'Unknown')
                if error_code == 'AccessDenied':
                    print("⚠️  WARNING: Bucket exists but list access is denied")
                else:
                    print(f"⚠️  Could not list bucket contents: {e}")
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code == 'AccessDenied':
                print("⚠️  WARNING: Bucket exists but some permissions are missing")
            else:
                print(f"⚠️  Could not retrieve bucket location: {e}")
        
        print()
        print("=" * 60)
        print("✅ BUCKET STATUS: EXISTS")
        print("=" * 60)
        return True
        
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        
        if error_code == '404':
            print(f"❌ BUCKET DOES NOT EXIST")
            print(f"The bucket '{settings.aws_s3_bucket_name}' was not found in AWS.")
            print()
            print("Possible reasons:")
            print("1. The bucket was deleted")
            print("2. The bucket name is incorrect")
            print("3. The bucket is in a different region")
            print()
            print("To create the bucket, go to AWS Console:")
            print(f"https://s3.console.aws.amazon.com/s3/buckets?region={settings.aws_region}")
            return False
            
        elif error_code == '403':
            print(f"⚠️  ACCESS DENIED")
            print(f"The bucket '{settings.aws_s3_bucket_name}' may exist, but you don't have permission to access it.")
            print()
            print("Possible reasons:")
            print("1. Your AWS credentials don't have the necessary permissions")
            print("2. The bucket exists but in a different AWS account")
            print("3. Bucket policy is restricting access")
            return False
            
        else:
            print(f"❌ ERROR checking bucket: {error_code}")
            print(f"Error details: {e}")
            return False
    
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    import sys
    try:
        success = check_bucket_exists()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nCheck interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

