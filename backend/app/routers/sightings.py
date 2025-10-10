from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime
import uuid
import os
from app.database import get_db
from app.models import Sighting as SightingModel, Species
from app.schemas import Sighting, SightingList, SightingCreate, SightingFilter

router = APIRouter()

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
        sighting = SightingModel(
            species_id=species_id,
            lat=lat,
            lon=lon,
            taken_at=datetime.utcnow(),
            is_private=is_private,
            media_url=file_path
        )
        
        db.add(sighting)
        db.commit()
        db.refresh(sighting)
        
        return sighting
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

