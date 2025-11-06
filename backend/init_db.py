#!/usr/bin/env python3
"""
Initialize the database with sample data
"""
import asyncio
from datetime import datetime, timedelta, timezone
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
            )
        ]
        
        for species in sample_species:
            db.add(species)
        db.flush()
        by_sci = {s.scientific_name: s for s in db.query(Species).all()}
        sample_sightings = [
            {
                "sci": "Bubo virginianus",
                "lat": 42.2804,
                "lon": -83.7436,
                "user": "Ada",
                "cap": "Perched near the Diag",
                "media_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Bubo_virginianus_06.jpg/500px-Bubo_virginianus_06.jpg",
                "taken_at": datetime(2025, 11, 4, 23, 23, tzinfo=timezone.utc)
            },
            {
                "sci": "Turdus migratorius",
                "lat": 42.2816,
                "lon": -83.7481,
                "user": "Robin",
                "cap": "Early worm run by the Arb",
                "media_url": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnPQnqDtQYt41FkzOkkeaDwzgJgqREvCRWfzLRU4_uSoZxpDs83MTYpPEIwqqKrhzmSsM2srR2kftPv46PB-SZkixbA_KIgpIpnDY6Ic8&s=10",
                "taken_at": datetime(2025, 10, 28, 7, 45, tzinfo=timezone.utc)
            },
            {
                "sci": "Buteo jamaicensis",
                "lat": 42.2791,
                "lon": -83.7392,
                "user": "Hawk",
                "cap": "Soaring over the Huron",
                "media_url": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTgO9RdL4piwhn7ybNxJ9H3_5gxssYXQOlW_CInZ3OqlGmkdiRdJVKQ1mkcKcgpd4otJUi801Wxt3CCfRzIxQei6nd9WXE5P5J2CWX_HO4&s=10",
                "taken_at": datetime(2025, 10, 28, 7, 21, tzinfo=timezone.utc)
            },
        ]
        for s in sample_sightings:
            db.add(Sighting(
                species_id=by_sci[s["sci"]].id,
                lat=s["lat"], lon=s["lon"],
                taken_at=s["taken_at"],
                is_private=False,
                username=s["user"],
                caption=s["cap"],
                media_url=s.get("media_url")
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

