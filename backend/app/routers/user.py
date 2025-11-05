# app/routers/user.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import User, Sighting, Species
from app.schemas import UserStats, FlashcardInfo

router = APIRouter(prefix="/v1", tags=["User"])

@router.get("/user/{user_id}", response_model=UserStats)
def get_user_stats_by_path(user_id: int, db: Session = Depends(get_db)):
    return _query_user_stats(user_id=user_id, db=db)


def _query_user_stats(user_id: int, db: Session) -> UserStats:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    total_sightings = (
        db.query(func.count(Sighting.id))
        .filter(Sighting.user_id == user_id)
        .scalar()
    ) or 0

    total_species = (
        db.query(func.count(func.distinct(Sighting.species_id)))
        .filter(Sighting.user_id == user_id)
        .scalar()
    ) or 0

    rows = (
        db.query(
            Species.name.label("species_name"),
            func.min(Sighting.timestamp).label("first_seen"),
            func.count(Sighting.id).label("num_sightings"),
        )
        .join(Species, Sighting.species_id == Species.id)
        .filter(Sighting.user_id == user_id)
        .group_by(Species.id, Species.name)
        .order_by(Species.name.asc())
        .all()
    )

    flashcards = [
        FlashcardInfo(
            species_name=r.species_name,
            first_seen=r.first_seen,
            num_sightings=r.num_sightings,
        )
        for r in rows
    ]

    return UserStats(
        user_id=user_id,
        total_sightings=total_sightings,
        total_species=total_species,
        flashcards=flashcards,
    )
