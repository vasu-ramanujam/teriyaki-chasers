from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime
import uuid
import os
from app.database import get_db
from app.models import Sighting as SightingModel, Species
from app.schemas import Sighting, SightingList, SightingCreate, SightingFilter, SightingDetail
from app.services.s3_service import S3Service
from app.config import settings

router = APIRouter()

# Initialize S3 service
s3_service = S3Service()

@router.get("/{sighting_id}", response_model=SightingDetail)
async def get_sighting(
    sighting_id: str,
    db: Session = Depends(get_db)
):
    """Get details of a single sighting"""
    try:
        # Query sighting with species information
        sighting = db.query(SightingModel).join(Species).filter(
            SightingModel.id == sighting_id
        ).first()
        
        if not sighting:
            raise HTTPException(status_code=404, detail="Sighting not found")
        
        # Format the response according to API documentation
        return SightingDetail(
            id=int(sighting.id) if sighting.id.isdigit() else hash(sighting.id) % 1000000,  # Convert to int for API
            species=sighting.species.scientific_name,  # Species observed
            location=f"{sighting.lat},{sighting.lon}",  # Location as lat,lon
            time=sighting.taken_at.isoformat(),  # Time in ISO format
            username=sighting.username or "Anonymous",  # User's display name
            is_private=sighting.is_private,  # Whether post is private
            caption=sighting.caption  # Optional caption
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=SightingList)
async def get_sightings(
    filter_data: SightingFilter,
    db: Session = Depends(get_db)
):
    """Get sightings filtered by area, species, and time range"""
    try:
        # Parse area (assuming it's a bounding box format: west,south,east,north)
        west, south, east, north = map(float, filter_data.area.split(','))
        
        # Base query - filter by lat/lon bounding box
        query = db.query(SightingModel).filter(
            and_(
                SightingModel.lat >= south,
                SightingModel.lat <= north,
                SightingModel.lon >= west,
                SightingModel.lon <= east
            )
        )
        
        # Apply filters
        if filter_data.start_time:
            start_dt = datetime.fromisoformat(filter_data.start_time.replace('Z', '+00:00'))
            query = query.filter(SightingModel.taken_at >= start_dt)
        
        if filter_data.end_time:
            end_dt = datetime.fromisoformat(filter_data.end_time.replace('Z', '+00:00'))
            query = query.filter(SightingModel.taken_at <= end_dt)
        
        if filter_data.species_id:
            query = query.filter(SightingModel.species_id == filter_data.species_id)
        
        # Order by most recent
        query = query.order_by(SightingModel.taken_at.desc()).limit(100)
        
        sightings = query.all()
        return SightingList(items=sightings)
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid filter format: {str(e)}")

@router.post("/create", response_model=Sighting)
async def create_sighting(
    species_id: int = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    is_private: bool = Form(False),
    username: Optional[str] = Form(None),
    caption: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    audio: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """
    Create a new sighting with optional photo and audio
    
    Args:
        species_id: ID of the species
        lat: Latitude
        lon: Longitude
        is_private: Whether the sighting is private
        username: Username of the uploader
        caption: Optional caption for the sighting
        photo: Optional image file
        audio: Optional audio file
    """
    try:
        # Verify species exists
        species = db.query(Species).filter(Species.id == species_id).first()
        if not species:
            raise HTTPException(status_code=404, detail="Species not found")
        
        # Require at least one media file
        if not photo and not audio:
            raise HTTPException(status_code=400, detail="At least one media file (photo or audio) is required")
        
        media_url = None
        audio_url = None
        
        # Upload photo to S3 if provided
        if photo:
            photo_content = await photo.read()
            photo_filename = f"{uuid.uuid4()}_{photo.filename}"
            content_type = s3_service.get_content_type(photo.filename)
            
            if settings.aws_s3_bucket_name:
                # Use S3
                media_url = await s3_service.upload_file(
                    file_content=photo_content,
                    file_name=photo_filename,
                    content_type=content_type,
                    folder="sightings/photos"
                )
            else:
                # Fallback to local storage
                os.makedirs("uploads/photos", exist_ok=True)
                file_path = f"uploads/photos/{photo_filename}"
                with open(file_path, "wb") as buffer:
                    buffer.write(photo_content)
                media_url = file_path
        
        # Upload audio to S3 if provided
        if audio:
            audio_content = await audio.read()
            audio_filename = f"{uuid.uuid4()}_{audio.filename}"
            content_type = s3_service.get_content_type(audio.filename)
            
            if settings.aws_s3_bucket_name:
                # Use S3
                audio_url = await s3_service.upload_file(
                    file_content=audio_content,
                    file_name=audio_filename,
                    content_type=content_type,
                    folder="sightings/audio"
                )
            else:
                # Fallback to local storage
                os.makedirs("uploads/audio", exist_ok=True)
                file_path = f"uploads/audio/{audio_filename}"
                with open(file_path, "wb") as buffer:
                    buffer.write(audio_content)
                audio_url = file_path
        
        # Create sighting
        sighting = SightingModel(
            species_id=species_id,
            lat=lat,
            lon=lon,
            taken_at=datetime.utcnow(),
            is_private=is_private,
            username=username,
            caption=caption,
            media_url=media_url,
            audio_url=audio_url
        )
        
        db.add(sighting)
        db.commit()
        db.refresh(sighting)
        
        return sighting
        
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

