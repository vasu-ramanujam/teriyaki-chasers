"""
Storage service for handling file uploads (images, audio)
Supports both local storage and S3-compatible cloud storage
"""
import os
import uuid
from typing import Optional, Tuple
from pathlib import Path
from datetime import datetime
from PIL import Image
import io

from fastapi import UploadFile, HTTPException
from app.config import settings


class StorageService:
    """Service for handling file uploads and storage"""
    
    # Allowed file types
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
    
    # File size limits (in bytes)
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB
    MAX_AUDIO_SIZE = 50 * 1024 * 1024  # 50 MB
    
    # Thumbnail settings
    THUMBNAIL_SIZE = (300, 300)
    
    def __init__(self):
        """Initialize storage service"""
        self.storage_type = settings.storage_type
        self.base_upload_dir = Path(settings.upload_directory)
        self.base_url = settings.api_base_url
        
        # Create upload directories if using local storage
        if self.storage_type == "local":
            self._setup_local_storage()
    
    def _setup_local_storage(self):
        """Create necessary directories for local storage"""
        directories = [
            self.base_upload_dir / "images",
            self.base_upload_dir / "images" / "thumbnails",
            self.base_upload_dir / "audio"
        ]
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
    
    def validate_file(
        self, 
        file: UploadFile, 
        file_type: str
    ) -> Tuple[bool, Optional[str]]:
        """
        Validate uploaded file
        
        Args:
            file: The uploaded file
            file_type: Either 'image' or 'audio'
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        if file_type == "image":
            allowed_types = self.ALLOWED_IMAGE_TYPES
            max_size = self.MAX_IMAGE_SIZE
        elif file_type == "audio":
            allowed_types = self.ALLOWED_AUDIO_TYPES
            max_size = self.MAX_AUDIO_SIZE
        else:
            return False, "Invalid file type specified"
        
        # Check content type
        if file.content_type not in allowed_types:
            return False, f"Invalid file type. Allowed: {', '.join(allowed_types.keys())}"
        
        # Check file size (if available)
        if hasattr(file, 'size') and file.size:
            if file.size > max_size:
                return False, f"File too large. Maximum size: {max_size / 1024 / 1024:.1f} MB"
        
        return True, None
    
    async def save_image(
        self, 
        file: UploadFile,
        create_thumbnail: bool = True
    ) -> Tuple[str, Optional[str]]:
        """
        Save an image file
        
        Args:
            file: The uploaded image file
            create_thumbnail: Whether to create a thumbnail
            
        Returns:
            Tuple of (file_url, thumbnail_url)
        """
        # Validate file
        is_valid, error = self.validate_file(file, "image")
        if not is_valid:
            raise HTTPException(status_code=400, detail=error)
        
        # Generate unique filename
        file_extension = Path(file.filename).suffix.lower()
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Read file content
        content = await file.read()
        
        if self.storage_type == "local":
            return await self._save_image_local(
                content, 
                unique_filename, 
                create_thumbnail
            )
        elif self.storage_type == "s3":
            return await self._save_image_s3(
                content, 
                unique_filename, 
                create_thumbnail
            )
        else:
            raise HTTPException(
                status_code=500, 
                detail="Invalid storage type configured"
            )
    
    async def _save_image_local(
        self, 
        content: bytes, 
        filename: str,
        create_thumbnail: bool
    ) -> Tuple[str, Optional[str]]:
        """Save image to local storage"""
        # Save original image
        image_path = self.base_upload_dir / "images" / filename
        with open(image_path, "wb") as f:
            f.write(content)
        
        image_url = f"{self.base_url}/uploads/images/{filename}"
        thumbnail_url = None
        
        # Create thumbnail if requested
        if create_thumbnail:
            try:
                thumbnail_url = await self._create_thumbnail_local(content, filename)
            except Exception as e:
                print(f"Failed to create thumbnail: {e}")
                # Don't fail the whole upload if thumbnail creation fails
        
        return image_url, thumbnail_url
    
    async def _create_thumbnail_local(
        self, 
        content: bytes, 
        filename: str
    ) -> str:
        """Create a thumbnail from image content"""
        # Open image with PIL
        image = Image.open(io.BytesIO(content))
        
        # Convert RGBA to RGB if needed
        if image.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            background.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
            image = background
        
        # Create thumbnail
        image.thumbnail(self.THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
        
        # Save thumbnail
        thumb_filename = f"thumb_{filename}"
        # Convert to .jpg for thumbnails to save space
        if not thumb_filename.endswith('.jpg'):
            thumb_filename = f"{Path(thumb_filename).stem}.jpg"
        
        thumb_path = self.base_upload_dir / "images" / "thumbnails" / thumb_filename
        image.save(thumb_path, "JPEG", quality=85, optimize=True)
        
        return f"{self.base_url}/uploads/images/thumbnails/{thumb_filename}"
    
    async def save_audio(self, file: UploadFile) -> str:
        """
        Save an audio file
        
        Args:
            file: The uploaded audio file
            
        Returns:
            Audio file URL
        """
        # Validate file
        is_valid, error = self.validate_file(file, "audio")
        if not is_valid:
            raise HTTPException(status_code=400, detail=error)
        
        # Generate unique filename
        file_extension = Path(file.filename).suffix.lower()
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Read file content
        content = await file.read()
        
        if self.storage_type == "local":
            return await self._save_audio_local(content, unique_filename)
        elif self.storage_type == "s3":
            return await self._save_audio_s3(content, unique_filename)
        else:
            raise HTTPException(
                status_code=500, 
                detail="Invalid storage type configured"
            )
    
    async def _save_audio_local(self, content: bytes, filename: str) -> str:
        """Save audio to local storage"""
        audio_path = self.base_upload_dir / "audio" / filename
        with open(audio_path, "wb") as f:
            f.write(content)
        
        return f"{self.base_url}/uploads/audio/{filename}"
    
    async def _save_image_s3(
        self, 
        content: bytes, 
        filename: str,
        create_thumbnail: bool
    ) -> Tuple[str, Optional[str]]:
        """Save image to S3-compatible storage"""
        # TODO: Implement S3 upload
        # This would use boto3 or similar library
        raise NotImplementedError("S3 storage not yet implemented")
    
    async def _save_audio_s3(self, content: bytes, filename: str) -> str:
        """Save audio to S3-compatible storage"""
        # TODO: Implement S3 upload
        raise NotImplementedError("S3 storage not yet implemented")
    
    async def delete_file(self, file_url: str) -> bool:
        """
        Delete a file from storage
        
        Args:
            file_url: The URL of the file to delete
            
        Returns:
            True if successful, False otherwise
        """
        if self.storage_type == "local":
            return self._delete_file_local(file_url)
        elif self.storage_type == "s3":
            return self._delete_file_s3(file_url)
        return False
    
    def _delete_file_local(self, file_url: str) -> bool:
        """Delete a file from local storage"""
        try:
            # Extract file path from URL
            url_path = file_url.replace(self.base_url, "")
            if url_path.startswith("/uploads/"):
                url_path = url_path[len("/uploads/"):]
            
            file_path = self.base_upload_dir / url_path
            
            if file_path.exists() and file_path.is_file():
                file_path.unlink()
                
                # Also delete thumbnail if it's an image
                if "/images/" in str(file_path):
                    thumb_filename = f"thumb_{file_path.name}"
                    if not thumb_filename.endswith('.jpg'):
                        thumb_filename = f"{Path(thumb_filename).stem}.jpg"
                    thumb_path = file_path.parent / "thumbnails" / thumb_filename
                    if thumb_path.exists():
                        thumb_path.unlink()
                
                return True
        except Exception as e:
            print(f"Error deleting file: {e}")
        
        return False
    
    def _delete_file_s3(self, file_url: str) -> bool:
        """Delete a file from S3 storage"""
        # TODO: Implement S3 deletion
        raise NotImplementedError("S3 storage not yet implemented")


# Global storage service instance
storage_service = StorageService()
