"""
S3 Storage Service with Presigned URL Generation
Direct client-to-S3 upload for better scalability and performance
"""
import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from typing import Dict, Optional
from datetime import datetime, timedelta
import uuid
from pathlib import Path

from app.config import settings


class S3Service:
    """Service for generating presigned URLs and managing S3 uploads"""
    
    # File type configurations
    ALLOWED_IMAGE_TYPES = {
        "image/jpeg": [".jpg", ".jpeg"],
        "image/png": [".png"],
        "image/heic": [".heic"],
        "image/heif": [".heif"],
        "image/webp": [".webp"]
    }
    
    ALLOWED_AUDIO_TYPES = {
        "audio/mpeg": [".mp3"],
        "audio/wav": [".wav"],
        "audio/x-m4a": [".m4a"],
        "audio/mp4": [".m4a"],
        "audio/ogg": [".ogg"]
    }
    
    # Size limits (in bytes)
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB
    MAX_AUDIO_SIZE = 50 * 1024 * 1024  # 50 MB
    
    # Presigned URL expiration
    PRESIGNED_URL_EXPIRATION = 300  # 5 minutes
    
    def __init__(self):
        """Initialize S3 client"""
        self.bucket_name = settings.s3_bucket_name
        self.cdn_domain = settings.cdn_domain
        
        # Initialize boto3 client
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.s3_access_key,
            aws_secret_access_key=settings.s3_secret_key,
            region_name=settings.s3_region,
            endpoint_url=settings.s3_endpoint_url,
            config=Config(signature_version='s3v4')
        )
    
    def _validate_content_type(self, content_type: str, media_type: str) -> bool:
        """Validate content type against allowed types"""
        if media_type == "image":
            return content_type in self.ALLOWED_IMAGE_TYPES
        elif media_type == "audio":
            return content_type in self.ALLOWED_AUDIO_TYPES
        return False
    
    def _generate_file_key(self, media_type: str, file_extension: str) -> str:
        """
        Generate a unique S3 key for the file
        
        Format: {media_type}/{year}/{month}/{uuid}.{ext}
        Example: images/2024/01/abc-123-def.jpg
        """
        now = datetime.utcnow()
        unique_id = str(uuid.uuid4())
        
        # Organize by type and date for better management
        key = f"{media_type}s/{now.year}/{now.month:02d}/{unique_id}{file_extension}"
        
        return key
    
    def generate_presigned_upload_url(
        self,
        filename: str,
        content_type: str,
        media_type: str,
        file_size: Optional[int] = None
    ) -> Dict[str, str]:
        """
        Generate a presigned URL for direct client upload to S3
        
        Args:
            filename: Original filename
            content_type: MIME type of the file
            media_type: Either 'image' or 'audio'
            file_size: Optional file size for validation
            
        Returns:
            Dict with presigned_url, file_key, and public_url
        """
        # Validate content type
        if not self._validate_content_type(content_type, media_type):
            raise ValueError(f"Invalid content type: {content_type} for {media_type}")
        
        # Validate file size
        max_size = self.MAX_IMAGE_SIZE if media_type == "image" else self.MAX_AUDIO_SIZE
        if file_size and file_size > max_size:
            raise ValueError(f"File too large. Maximum: {max_size / 1024 / 1024:.1f} MB")
        
        # Get file extension
        file_extension = Path(filename).suffix.lower()
        if not file_extension:
            # Get default extension from content type
            allowed_types = self.ALLOWED_IMAGE_TYPES if media_type == "image" else self.ALLOWED_AUDIO_TYPES
            file_extension = allowed_types[content_type][0]
        
        # Generate unique key
        file_key = self._generate_file_key(media_type, file_extension)
        
        # Generate presigned URL
        try:
            presigned_url = self.s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': file_key,
                    'ContentType': content_type,
                    'ContentLength': file_size if file_size else None,
                    'Metadata': {
                        'original-filename': filename,
                        'upload-timestamp': datetime.utcnow().isoformat()
                    }
                },
                ExpiresIn=self.PRESIGNED_URL_EXPIRATION,
                HttpMethod='PUT'
            )
            
            # Generate public URL (using CDN if configured)
            public_url = self.get_public_url(file_key)
            
            return {
                "presigned_url": presigned_url,
                "file_key": file_key,
                "public_url": public_url,
                "expires_in": self.PRESIGNED_URL_EXPIRATION
            }
            
        except ClientError as e:
            raise Exception(f"Failed to generate presigned URL: {str(e)}")
    
    def generate_presigned_upload_urls_batch(
        self,
        uploads: list[Dict]
    ) -> Dict[str, Dict[str, str]]:
        """
        Generate multiple presigned URLs at once
        
        Args:
            uploads: List of dicts with filename, content_type, media_type
            
        Returns:
            Dict mapping upload IDs to presigned URL info
        """
        results = {}
        
        for upload in uploads:
            upload_id = upload.get('upload_id', str(uuid.uuid4()))
            try:
                result = self.generate_presigned_upload_url(
                    filename=upload['filename'],
                    content_type=upload['content_type'],
                    media_type=upload['media_type'],
                    file_size=upload.get('file_size')
                )
                results[upload_id] = {
                    "success": True,
                    **result
                }
            except Exception as e:
                results[upload_id] = {
                    "success": False,
                    "error": str(e)
                }
        
        return results
    
    def get_public_url(self, file_key: str) -> str:
        """
        Get the public URL for a file
        Uses CDN domain if configured, otherwise S3 direct URL
        """
        if self.cdn_domain:
            # Use CDN for optimized delivery
            return f"https://{self.cdn_domain}/{file_key}"
        else:
            # Direct S3 URL
            if settings.s3_endpoint_url:
                # Custom endpoint (e.g., DigitalOcean Spaces)
                base_url = settings.s3_endpoint_url.rstrip('/')
                return f"{base_url}/{self.bucket_name}/{file_key}"
            else:
                # Standard AWS S3 URL
                return f"https://{self.bucket_name}.s3.{settings.s3_region}.amazonaws.com/{file_key}"
    
    def verify_upload_completed(self, file_key: str) -> bool:
        """
        Verify that a file was successfully uploaded to S3
        
        Args:
            file_key: The S3 key of the file
            
        Returns:
            True if file exists, False otherwise
        """
        try:
            self.s3_client.head_object(Bucket=self.bucket_name, Key=file_key)
            return True
        except ClientError:
            return False
    
    def delete_file(self, file_key: str) -> bool:
        """
        Delete a file from S3
        
        Args:
            file_key: The S3 key of the file
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=file_key)
            return True
        except ClientError as e:
            print(f"Error deleting file: {e}")
            return False
    
    def get_file_metadata(self, file_key: str) -> Optional[Dict]:
        """
        Get metadata for a file in S3
        
        Args:
            file_key: The S3 key of the file
            
        Returns:
            Dict with metadata or None if file doesn't exist
        """
        try:
            response = self.s3_client.head_object(Bucket=self.bucket_name, Key=file_key)
            return {
                "content_type": response.get('ContentType'),
                "content_length": response.get('ContentLength'),
                "last_modified": response.get('LastModified'),
                "metadata": response.get('Metadata', {})
            }
        except ClientError:
            return None


# Global S3 service instance
s3_service = S3Service() if settings.storage_type == "s3" else None
