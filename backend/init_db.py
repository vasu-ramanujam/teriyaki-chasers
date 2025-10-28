#!/usr/bin/env python3
"""
Initialize the database with sample data
"""
import asyncio
from datetime import datetime
from sqlalchemy.orm import sessionmaker
from app.database import engine, Base
from app.models import Species, Sighting
import uuid

def init_database():
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    # Create session
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Check if species already exist
        if db.query(Species).count() > 0:
            print("Database already initialized")
            return
        
        # Add sample species
        sample_species = [
            Species(
                common_name="Great Horned Owl",
                scientific_name="Bubo virginianus",
                habitat="Forests, deserts, and urban areas",
                diet="Small mammals, birds, reptiles",
                behavior="Nocturnal hunter with excellent hearing"
            ),
            Species(
                common_name="American Robin",
                scientific_name="Turdus migratorius",
                habitat="Gardens, parks, and woodlands",
                diet="Earthworms, insects, berries",
                behavior="Active during day, known for early morning singing"
            ),
            Species(
                common_name="Red-tailed Hawk",
                scientific_name="Buteo jamaicensis",
                habitat="Open country, woodlands, and urban areas",
                diet="Small mammals, birds, reptiles",
                behavior="Soaring hunter with distinctive red tail"
            ),
            Species(
                common_name="White-tailed Deer",
                scientific_name="Odocoileus virginianus",
                habitat="Forests, fields, and suburban areas",
                diet="Grasses, leaves, twigs, acorns",
                behavior="Most active at dawn and dusk"
            ),
            Species(
                common_name="Eastern Gray Squirrel",
                scientific_name="Sciurus carolinensis",
                habitat="Urban parks and woodlands",
                diet="Nuts, seeds, fruits, and insects",
                behavior="Diurnal, excellent climbers and jumpers"
            )
        ]
        
        for species in sample_species:
            db.add(species)
        db.flush()
        by_sci = {s.scientific_name: s for s in db.query(Species).all()}
        now = datetime.utcnow()
        # sample lat, longs at the dude
        # "lat": 42.2911208, "lon": -83.7159276
        # "lat": 42.2912344, "lon": -83.7159963
        # "lat": 42.2912455, "lon": -83.7159920

        sample_sightings = [
            {"sci": "Bubo virginianus",     "lat": 42.2776062, "lon": -83.7315065, "user": "Ada",   "cap": "Perched on the oak"},
            {"sci": "Turdus migratorius",   "lat": 42.2777608, "lon": -83.7315565, "user": "Robin", "cap": "Early worm run"},
            {"sci": "Buteo jamaicensis",    "lat": 42.2777565, "lon": -83.7316044, "user": "Hawk",  "cap": "Soaring over meadow"},
        ]
        for s in sample_sightings:
            db.add(Sighting(
                species_id=by_sci[s["sci"]].id,
                lat=s["lat"], lon=s["lon"],
                taken_at=now,
                is_private=False,
                username=s["user"],
                caption=s["cap"],
                media_url=None
            ))
        
        db.commit()
        print("Database initialized with sample species and sightings")
        
    except Exception as e:
        print(f"Error initializing database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_database()

