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
            caption=sighting.caption,  # Optional caption
            media_url=sighting.media_url,  # Optional S3 URL for image
            audio_url=sighting.audio_url  # Optional S3 URL for audio
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
    """Get sightings filtered by area, species, time range, and/or username"""
    try:
        print("inside get sightings post req") # DEBUG
        
        # Start with base query
        query = db.query(SightingModel)
        
        print("hola\n\n")

        # Filter by area (bounding box) if provided
        if filter_data.area:
            try:
                west, south, east, north = map(float, filter_data.area.split(','))
                query = query.filter(
                    and_(
                        SightingModel.lat >= south,
                        SightingModel.lat <= north,
                        SightingModel.lon >= west,
                        SightingModel.lon <= east
                    )
                )
            except (ValueError, AttributeError) as e:
                raise HTTPException(status_code=400, detail=f"Invalid area format. Expected: west,south,east,north. Error: {str(e)}")
        
        print("hi\n\n")

        # Filter by username if provided (may match multiple users if duplicates exist)
        if filter_data.username:
            query = query.filter(SightingModel.username == filter_data.username)
        
        # Filter by time range if provided
        if filter_data.start_time:
            try:
                start_dt = datetime.fromisoformat(filter_data.start_time.replace('Z', '+00:00'))
                query = query.filter(SightingModel.taken_at >= start_dt)
            except ValueError as e:
                raise HTTPException(status_code=400, detail=f"Invalid start_time format: {str(e)}")
        
        if filter_data.end_time:
            try:
                end_dt = datetime.fromisoformat(filter_data.end_time.replace('Z', '+00:00'))
                query = query.filter(SightingModel.taken_at <= end_dt)
            except ValueError as e:
                raise HTTPException(status_code=400, detail=f"Invalid end_time format: {str(e)}")
        
        print(filter_data) #debug

        # Filter by species if provided
        if filter_data.species_id:
            query = query.filter(SightingModel.species_id == filter_data.species_id)

        
        # Ensure at least one filter is provided
        if not any([
            filter_data.area,
            filter_data.username,
            filter_data.start_time,
            filter_data.end_time,
            filter_data.species_id
        ]):
            raise HTTPException(
                status_code=400,
                detail="At least one filter parameter must be provided (area, user_id, username, start_time, end_time, or species_id)"
            )
        
        
        
        # Order by most recent and limit results
        query = query.order_by(SightingModel.taken_at.desc()).limit(100)
        
        print(query)
        print("wassup\n\n")
        # Debug: Log the query (optional, remove in production)
        sightings = query.all()
        print(sightings)
        
        print(SightingList(items=sightings)) #debug
        return SightingList(items=sightings)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid filter format: {str(e)}")

@router.post("/create", response_model=Sighting)
async def create_sighting(
    species_id: int = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    is_private: bool = Form(False),
    user_id: Optional[str] = Form(None),  # Unique user identifier (recommended)
    username: Optional[str] = Form(None),  # User's display name
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
        user_id: Unique user identifier (recommended for filtering)
        username: User's display name
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
            user_id=user_id,
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

