from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime
import uuid
import os

# Only import geo functions if not in testing mode
TESTING = os.getenv("TESTING", "0") == "1"
if not TESTING:
    from geoalchemy2 import functions as geo_func

from app.database import get_db
from app.models import Sighting as SightingModel, Species
from app.schemas import Sighting as SightingSchema, SightingList, SightingCreate, SightingUpdate

router = APIRouter()

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
    photo: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Create a new sighting with photo"""
    try:
        # Verify species exists
        species = db.query(Species).filter(Species.id == species_id).first()
        if not species:
            raise HTTPException(status_code=404, detail="Species not found")
        
        # Save uploaded file (for now, save locally)
        os.makedirs("uploads", exist_ok=True)
        file_path = f"uploads/{uuid.uuid4()}_{photo.filename}"
        with open(file_path, "wb") as buffer:
            content = await photo.read()
            buffer.write(content)
        
        # Create sighting
        sighting_data = {
            "species_id": species_id,
            "lat": lat,
            "lon": lon,
            "taken_at": datetime.utcnow(),
            "is_private": is_private,
            "media_url": file_path
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

