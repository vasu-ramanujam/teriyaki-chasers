from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from app.database import get_db
from app.models import Species as SpeciesModel
from app.schemas import Species, SpeciesSearch

router = APIRouter()

@router.get("/", response_model=SpeciesSearch)
async def search_species(
    q: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Search species by common or scientific name"""
    query = db.query(SpeciesModel).filter(
        func.lower(SpeciesModel.common_name).contains(q.lower()) |
        func.lower(SpeciesModel.scientific_name).contains(q.lower())
    ).limit(limit)
    
    species_list = query.all()
    return SpeciesSearch(items=species_list)

@router.get("/{species_id}", response_model=Species)
async def get_species(
    species_id: str,
    db: Session = Depends(get_db)
):
    """Get species details by ID"""
    species = db.query(SpeciesModel).filter(SpeciesModel.id == species_id).first()
    if not species:
        raise HTTPException(status_code=404, detail="Species not found")
    return species

