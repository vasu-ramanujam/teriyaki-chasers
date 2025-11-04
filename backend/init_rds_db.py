#!/usr/bin/env python3
"""
Initialize RDS PostgreSQL database with schema and optionally sample data
"""
import sys
from datetime import datetime
from sqlalchemy.orm import sessionmaker
from app.database import engine, Base
from app.models import Species, Sighting
from app.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_rds_database(seed_data: bool = False):
    """
    Initialize RDS database with schema
    
    Args:
        seed_data: If True, add sample data for testing
    """
    database_url = settings.get_database_url()
    
    # Check if using PostgreSQL
    if not database_url.startswith("postgresql"):
        logger.error("This script is for RDS PostgreSQL. Current database is not PostgreSQL.")
        logger.info(f"Current database URL: {database_url}")
        logger.info("To use RDS, configure RDS_HOST, RDS_USERNAME, RDS_PASSWORD, RDS_DATABASE in .env")
        sys.exit(1)
    
    logger.info(f"Connecting to: {database_url.split('@')[1] if '@' in database_url else 'RDS instance'}")
    
    try:
        # Test connection first
        logger.info("Testing database connection...")
        from sqlalchemy import text
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            logger.info(f"✅ Connected to PostgreSQL: {version[:50]}...")
        
        # Create all tables
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Tables created successfully")
        
        if seed_data:
            # Create session for adding data
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            db = SessionLocal()
            
            try:
                # Check if species already exist
                if db.query(Species).count() > 0:
                    logger.info("Database already contains data. Skipping seed data.")
                    return
                
                logger.info("Adding sample species and sightings...")
                
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
                
                # Get species IDs for sightings
                by_sci = {s.scientific_name: s for s in db.query(Species).all()}
                now = datetime.now()
                
                # Sample sightings with user_id for testing filtering
                sample_sightings = [
                    {"sci": "Bubo virginianus",     "lat": 37.3340, "lon": -122.0090, "user_id": "user_001", "user": "Ada",   "cap": "Perched on the oak"},
                    {"sci": "Turdus migratorius",   "lat": 37.3332, "lon": -122.0101, "user_id": "user_002", "user": "Robin", "cap": "Early worm run"},
                    {"sci": "Buteo jamaicensis",    "lat": 37.3352, "lon": -122.0063, "user_id": "user_001", "user": "Ada",   "cap": "Soaring over meadow"},
                    {"sci": "Turdus migratorius",   "lat": 37.3345, "lon": -122.0085, "user_id": "user_001", "user": "Ada",   "cap": "Another robin sighting"},
                ]
                
                for s in sample_sightings:
                    db.add(Sighting(
                        species_id=by_sci[s["sci"]].id,
                        lat=s["lat"], lon=s["lon"],
                        taken_at=now,
                        is_private=False,
                        user_id=s["user_id"],
                        username=s["user"],
                        caption=s["cap"],
                        media_url=None
                    ))
                
                db.commit()
                logger.info("✅ Sample data added successfully")
                
            except Exception as e:
                logger.error(f"Error adding seed data: {e}")
                db.rollback()
                raise
            finally:
                db.close()
        else:
            logger.info("Skipping seed data (use --seed to add sample data)")
        
        logger.info("\n✅ RDS database initialized successfully!")
        logger.info("\nNext steps:")
        logger.info("1. Test connection: python3 test_rds_connection.py")
        logger.info("2. Start server: python3 run.py")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")
        sys.exit(1)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Initialize RDS PostgreSQL database")
    parser.add_argument("--seed", action="store_true", help="Add sample data for testing")
    args = parser.parse_args()
    
    init_rds_database(seed_data=args.seed)

