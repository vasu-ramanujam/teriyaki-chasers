from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
import uuid
import os

# Only import geo functions if not in testing mode
TESTING = os.getenv("TESTING", "0") == "1"
if not TESTING:
    from geoalchemy2 import functions as geo_func

from app.database import get_db
from app.models import Sighting as SightingModel, Species
from app.schemas import Sighting as SightingSchema, SightingList, SightingCreate, SightingUpdate
from app.services.storage import storage_service
from app.services.s3_service import s3_service
from app.config import settings

router = APIRouter()


# Request/Response models for presigned URLs
class PresignedUrlRequest(BaseModel):
    media_type: str  # "image" or "audio"
    content_type: str  # e.g., "image/jpeg", "audio/mpeg"
    file_extension: str  # e.g., "jpg", "mp3"


class PresignedUrlResponse(BaseModel):
    upload_url: str  # Presigned URL for uploading
    file_key: str  # S3 key for the file
    public_url: str  # URL to access the file after upload
    expires_in: int = 300  # Seconds until URL expires


@router.post("/upload-url", response_model=PresignedUrlResponse)
async def get_upload_url(request: PresignedUrlRequest):
    """
    Generate a presigned URL for direct S3 upload.
    
    This endpoint enables the client to upload files directly to S3 without
    going through the backend server, improving scalability and performance.
    
    Flow:
    1. Client requests presigned URL with media type and content type
    2. Backend generates presigned URL and returns it with file key
    3. Client uploads file directly to S3 using the presigned URL (PUT request)
    4. Client creates sighting with the file_key and public_url
    """
    # Only available when using S3 storage
    if settings.storage_type != "s3":
        raise HTTPException(
            status_code=501,
            detail="Presigned URLs are only available when storage_type is 's3'. Current storage type is 'local'."
        )
    
    # Validate media type
    if request.media_type not in ["image", "audio"]:
        raise HTTPException(
            status_code=400,
            detail="media_type must be 'image' or 'audio'"
        )
    
    try:
        # Generate presigned URL
        upload_url, file_key = s3_service.generate_presigned_upload_url(
            media_type=request.media_type,
            content_type=request.content_type,
            file_extension=request.file_extension
        )
        
        # Get public URL (will use CDN if configured)
        public_url = s3_service.get_public_url(file_key)
        
        return PresignedUrlResponse(
            upload_url=upload_url,
            file_key=file_key,
            public_url=public_url,
            expires_in=300
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate upload URL: {str(e)}")


@router.get("/", response_model=SightingList)
async def get_sightings(
    bbox: str = Query(..., description="Bounding box: west,south,east,north"),
    since: Optional[str] = Query(None, description="ISO8601 timestamp"),
    species_id: Optional[str] = Query(None, description="Species ID filter"),
    db: Session = Depends(get_db)
):
    """Get sightings within bounding box with optional filters"""
    try:
        # Parse bbox
        west, south, east, north = map(float, bbox.split(','))
        
        # Query based on environment
        if TESTING:
            # Use simple lat/lon bounding box for testing (SQLite)
            query = db.query(SightingModel).filter(
                and_(
                    SightingModel.lat >= south,
                    SightingModel.lat <= north,
                    SightingModel.lon >= west,
                    SightingModel.lon <= east
                )
            )
        else:
            # Use PostGIS spatial queries for production (PostgreSQL)
            bbox_geom = geo_func.ST_MakeEnvelope(west, south, east, north, 4326)
            query = db.query(SightingModel).filter(
                geo_func.ST_Intersects(SightingModel.geom, bbox_geom)
            )
        
        # Apply filters
        if since:
            since_dt = datetime.fromisoformat(since.replace('Z', '+00:00'))
            query = query.filter(SightingModel.taken_at >= since_dt)
        
        if species_id:
            query = query.filter(SightingModel.species_id == species_id)
        
        # Order by most recent
        query = query.order_by(SightingModel.taken_at.desc()).limit(100)
        
        sightings = query.all()
        return SightingList(items=sightings)
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid bbox format: {str(e)}")

@router.post("/", response_model=SightingSchema)
async def create_sighting(
    species_id: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    is_private: bool = Form(False),
    username: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    audio: Optional[UploadFile] = File(None),
    photo_url: Optional[str] = Form(None),
    photo_thumb_url: Optional[str] = Form(None),
    audio_url: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Create a new sighting with media.
    
    Supports two modes:
    1. Direct upload: Upload photo/audio files directly (local storage)
    2. S3 presigned URLs: Provide URLs after uploading to S3 (scalable)
    
    For S3 flow:
    1. Call POST /api/sightings/upload-url to get presigned URL
    2. Upload file directly to S3 using presigned URL
    3. Call this endpoint with photo_url/audio_url parameters
    """
    try:
        # Verify species exists
        species = db.query(Species).filter(Species.id == species_id).first()
        if not species:
            raise HTTPException(status_code=404, detail="Species not found")
        
        # At least one media source is required (either file or URL)
        has_media = photo or audio or photo_url or audio_url
        if not has_media:
            raise HTTPException(
                status_code=400, 
                detail="At least one media file or URL (photo or audio) is required"
            )
        
        # Process photo
        media_url = None
        media_thumb_url = None
        
        if photo:
            # Direct file upload (local storage)
            media_url, media_thumb_url = await storage_service.save_image(photo)
        elif photo_url:
            # S3 URL provided
            media_url = photo_url
            media_thumb_url = photo_thumb_url  # Optional, can be None
        
        # Process audio
        final_audio_url = None
        
        if audio:
            # Direct file upload (local storage)
            final_audio_url = await storage_service.save_audio(audio)
        elif audio_url:
            # S3 URL provided
            final_audio_url = audio_url
        
        # Create sighting
        sighting_data = {
            "species_id": species_id,
            "lat": lat,
            "lon": lon,
            "taken_at": datetime.utcnow(),
            "is_private": is_private,
            "username": username,
            "media_url": media_url,
            "media_thumb_url": media_thumb_url,
            "audio_url": final_audio_url,
            "notes": notes
        }
        
        # Add geometry only in production
        if not TESTING:
            sighting_data["geom"] = f"POINT({lon} {lat})"
        
        sighting = SightingModel(**sighting_data)
        
        db.add(sighting)
        db.commit()
        db.refresh(sighting)
        
        return sighting
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{id}", response_model=SightingSchema)
async def update_sighting(
    id: str,
    sighting_update: SightingUpdate,
    db: Session = Depends(get_db)
):
    """Update a sighting (author only)"""
    try:
        # Find the sighting
        sighting = db.query(SightingModel).filter(SightingModel.id == id).first()
        if not sighting:
            raise HTTPException(status_code=404, detail="Sighting not found")
        
        # TODO: Add authentication check to ensure only the author can edit
        # For now, we'll allow any user to edit any sighting
        # if current_user.id != sighting.user_id:
        #     raise HTTPException(status_code=403, detail="Not authorized to edit this sighting")
        
        # Update fields if provided
        if sighting_update.location is not None:
            try:
                # Parse location format "lat,lon"
                lat_str, lon_str = sighting_update.location.split(',')
                lat = float(lat_str.strip())
                lon = float(lon_str.strip())
                sighting.lat = lat
                sighting.lon = lon
            except (ValueError, AttributeError):
                raise HTTPException(status_code=400, detail="Invalid location format. Expected 'lat,lon'")
        
        if sighting_update.time is not None:
            try:
                # Parse ISO8601 datetime string
                sighting.taken_at = datetime.fromisoformat(sighting_update.time.replace('Z', '+00:00'))
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid time format. Expected ISO8601 format")
        
        if sighting_update.notes is not None:
            sighting.notes = sighting_update.notes
        
        db.commit()
        db.refresh(sighting)
        
        return sighting
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

