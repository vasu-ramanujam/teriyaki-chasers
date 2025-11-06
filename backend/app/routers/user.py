# app/routers/user.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import User, Sighting, Species
from app.schemas import UserStats, FlashcardInfo

router = APIRouter() #prefix="/v1", tags=["user"])

@router.get("/{username}", response_model=UserStats)
def get_user_stats_by_path(username: str, db: Session = Depends(get_db)):
    return _query_user_stats(username=username, db=db)


def _query_user_stats(username: str, db: Session) -> UserStats:
    #usre_id is actually the username!!!!
    total_sightings = (
        db.query(func.count(Sighting.id))
        .filter(Sighting.username == username)
        .scalar()
    ) or 0

    total_species = (
        db.query(func.count(func.distinct(Sighting.species_id)))
        .filter(Sighting.username == username)
        .scalar()
    ) or 0

    rows = (
        db.query(
            Species.id.label("species_id"),
            Species.common_name.label("species_name"),
            func.min(Sighting.created_at).label("first_seen"),
            func.count(Sighting.id).label("num_sightings"),
        )
        .join(Species, Sighting.species_id == Species.id)
        .filter(Sighting.username == username)
        .group_by(Species.id, Species.common_name)
        .order_by(Species.common_name.asc())
        .all()
    )
    
    print(len(rows))#debug

    flashcards = [
        FlashcardInfo(
            species_id=r.species_id,
            species_name=r.species_name,
            first_seen=r.first_seen,
            num_sightings=r.num_sightings,
        )
        for r in rows
    ]

    print(flashcards)
    
    return UserStats(
        username=username,
        total_sightings=total_sightings,
        total_species=total_species,
        flashcards=flashcards,
    )
