#!/usr/bin/env python3
"""
Initialize the database with sample data
"""
import asyncio
from sqlalchemy.orm import sessionmaker
from app.database import engine, Base
from app.models import Species
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
                id=uuid.uuid4(),
                common_name="Great Horned Owl",
                scientific_name="Bubo virginianus",
                habitat="Forests, deserts, and urban areas",
                diet="Small mammals, birds, reptiles",
                behavior="Nocturnal hunter with excellent hearing"
            ),
            Species(
                id=uuid.uuid4(),
                common_name="American Robin",
                scientific_name="Turdus migratorius",
                habitat="Gardens, parks, and woodlands",
                diet="Earthworms, insects, berries",
                behavior="Active during day, known for early morning singing"
            ),
            Species(
                id=uuid.uuid4(),
                common_name="Red-tailed Hawk",
                scientific_name="Buteo jamaicensis",
                habitat="Open country, woodlands, and urban areas",
                diet="Small mammals, birds, reptiles",
                behavior="Soaring hunter with distinctive red tail"
            ),
            Species(
                id=uuid.uuid4(),
                common_name="White-tailed Deer",
                scientific_name="Odocoileus virginianus",
                habitat="Forests, fields, and suburban areas",
                diet="Grasses, leaves, twigs, acorns",
                behavior="Most active at dawn and dusk"
            ),
            Species(
                id=uuid.uuid4(),
                common_name="Eastern Gray Squirrel",
                scientific_name="Sciurus carolinensis",
                habitat="Urban parks and woodlands",
                diet="Nuts, seeds, fruits, and insects",
                behavior="Diurnal, excellent climbers and jumpers"
            )
        ]
        
        for species in sample_species:
            db.add(species)
        
        db.commit()
        print("Database initialized with sample species")
        
    except Exception as e:
        print(f"Error initializing database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_database()

