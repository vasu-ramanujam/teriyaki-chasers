from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from geoalchemy2 import functions as geo_func
from typing import List, Optional
from datetime import datetime
import uuid
import os
from app.database import get_db
from app.models import Sighting, Species
from app.schemas import Sighting, SightingList, SightingCreate

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
        
        # Create bounding box geometry
        bbox_geom = geo_func.ST_MakeEnvelope(west, south, east, north, 4326)
        
        # Base query
        query = db.query(Sighting).filter(
            geo_func.ST_Intersects(Sighting.geom, bbox_geom)
        )
        
        # Apply filters
        if since:
            since_dt = datetime.fromisoformat(since.replace('Z', '+00:00'))
            query = query.filter(Sighting.taken_at >= since_dt)
        
        if species_id:
            query = query.filter(Sighting.species_id == species_id)
        
        # Order by most recent
        query = query.order_by(Sighting.taken_at.desc()).limit(100)
        
        sightings = query.all()
        return SightingList(items=sightings)
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid bbox format: {str(e)}")

@router.post("/", response_model=Sighting)
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
        sighting = Sighting(
            species_id=species_id,
            geom=f"POINT({lon} {lat})",
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

