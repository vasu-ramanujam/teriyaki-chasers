import boto3
from botocore.exceptions import ClientError
import os
from typing import Optional
from app.config import settings

class S3Service:
    """Service for handling S3 file uploads"""
    
    def __init__(self):
        self.s3_client = None
        self.bucket_name = settings.aws_s3_bucket_name
        
        # Only initialize S3 client if credentials are available
        if settings.aws_access_key_id and settings.aws_secret_access_key and settings.aws_s3_bucket_name:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                region_name=settings.aws_region
            )
        
    async def upload_file(
        self, 
        file_content: bytes, 
        file_name: str, 
        content_type: str,
        folder: str = "sightings"
    ) -> str:
        """
        Upload a file to S3 and return the public URL
        
        Args:
            file_content: The file content as bytes
            file_name: The name to save the file as in S3
            content_type: The MIME type of the file (e.g., 'image/jpeg', 'audio/mpeg')
            folder: The folder prefix in S3 (e.g., 'sightings', 'audio')
            
        Returns:
            The public URL of the uploaded file
        """
        try:
            # Create the S3 key (path)
            s3_key = f"{folder}/{file_name}"
            
            # Upload file to S3
            if self.s3_client is None:
                raise Exception("S3 client not initialized. Please configure AWS credentials in .env file.")
            
            # Try to upload with ACL first (for buckets with ACL enabled)
            try:
                self.s3_client.put_object(
                    Bucket=self.bucket_name,
                    Key=s3_key,
                    Body=file_content,
                    ContentType=content_type,
                    ACL='public-read'  # Make file publicly accessible
                )
            except Exception as e:
                # If ACL is not supported, upload without ACL and make bucket public
                if 'AccessControlListNotSupported' in str(e) or 'Invalid request' in str(e):
                    self.s3_client.put_object(
                        Bucket=self.bucket_name,
                        Key=s3_key,
                        Body=file_content,
                        ContentType=content_type
                    )
                else:
                    raise
            
            # Generate public URL
            url = f"https://{self.bucket_name}.s3.{settings.aws_region}.amazonaws.com/{s3_key}"
            
            return url
            
        except ClientError as e:
            print(f"Error uploading file to S3: {e}")
            raise Exception(f"Failed to upload file to S3: {str(e)}")
    
    async def delete_file(self, file_url: str) -> bool:
        """
        Delete a file from S3 based on its URL
        
        Args:
            file_url: The public URL of the file to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Extract the key from the URL
            # URL format: https://bucket-name.s3.region.amazonaws.com/folder/filename
            parts = file_url.split('.amazonaws.com/')
            if len(parts) != 2:
                return False
                
            s3_key = parts[1]
            
            # Delete the object
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            
            return True
            
        except ClientError as e:
            print(f"Error deleting file from S3: {e}")
            return False
    
    def get_content_type(self, filename: str) -> str:
        """
        Determine content type based on file extension
        
        Args:
            filename: The filename
            
        Returns:
            MIME type string
        """
        extension = filename.split('.')[-1].lower() if '.' in filename else ''
        
        content_types = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp',
            'mp3': 'audio/mpeg',
            'wav': 'audio/wav',
            'm4a': 'audio/mp4',
            'ogg': 'audio/ogg',
            'flac': 'audio/flac',
        }
        
        return content_types.get(extension, 'application/octet-stream')

