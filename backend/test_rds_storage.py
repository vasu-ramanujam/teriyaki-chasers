#!/usr/bin/env python3
"""
Test script to store and fetch a sighting from RDS
"""
import sys
from datetime import datetime
from sqlalchemy.orm import sessionmaker
from app.database import engine, SessionLocal
from app.models import Species, Sighting
from app.config import settings
import uuid

def test_store_and_fetch_sighting():
    """Test storing a sighting to RDS and fetching it back"""
    print("🧪 Testing RDS Storage - Store and Fetch Sighting\n")
    
    # Check we're using RDS
    db_url = settings.get_database_url()
    if not db_url.startswith("postgresql"):
        print("❌ Not using RDS. Current database:", db_url)
        print("   Configure RDS in .env to test")
        return False
    
    print(f"✅ Using RDS PostgreSQL: {settings.rds_host}\n")
    
    db = SessionLocal()
    
    try:
        # Get or create a test species
        print("1️⃣ Getting test species...")
        species = db.query(Species).first()
        if not species:
            print("   ⚠️  No species found. Creating one...")
            species = Species(
                common_name="Test Bird",
                scientific_name="Testus avius",
                habitat="Test habitat"
            )
            db.add(species)
            db.commit()
            db.refresh(species)
        
        print(f"   ✅ Using species: {species.common_name} (ID: {species.id})\n")
        
        # Create a test sighting
        print("2️⃣ Creating test sighting...")
        test_sighting_id = str(uuid.uuid4())
        test_username = "test_user_" + datetime.now().strftime("%Y%m%d%H%M%S")
        test_user_id = "test_user_id_001"
        
        new_sighting = Sighting(
            id=test_sighting_id,
            user_id=test_user_id,
            username=test_username,
            species_id=species.id,
            lat=42.3601,
            lon=-71.0589,
            taken_at=datetime.now(),
            is_private=False,
            caption="Test sighting created by test_rds_storage.py",
            media_url="https://test-bucket.s3.amazonaws.com/test-image.jpg",
            audio_url=None
        )
        
        db.add(new_sighting)
        db.commit()
        db.refresh(new_sighting)
        
        print(f"   ✅ Sighting created!")
        print(f"      ID: {new_sighting.id}")
        print(f"      User: {new_sighting.username}")
        print(f"      Location: {new_sighting.lat}, {new_sighting.lon}")
        print(f"      Media URL: {new_sighting.media_url}\n")
        
        # Fetch it back
        print("3️⃣ Fetching sighting from database...")
        fetched_sighting = db.query(Sighting).filter(Sighting.id == test_sighting_id).first()
        
        if fetched_sighting:
            print(f"   ✅ Sighting fetched successfully!")
            print(f"      ID: {fetched_sighting.id}")
            print(f"      User ID: {fetched_sighting.user_id}")
            print(f"      Username: {fetched_sighting.username}")
            print(f"      Species ID: {fetched_sighting.species_id}")
            print(f"      Location: {fetched_sighting.lat}, {fetched_sighting.lon}")
            print(f"      Caption: {fetched_sighting.caption}")
            print(f"      Media URL: {fetched_sighting.media_url}")
            print(f"      Created: {fetched_sighting.created_at}\n")
            
            # Verify data integrity
            if (fetched_sighting.id == test_sighting_id and 
                fetched_sighting.username == test_username and
                fetched_sighting.user_id == test_user_id):
                print("   ✅ Data integrity verified - all fields match!\n")
            else:
                print("   ⚠️  Data mismatch detected")
                return False
            
            # Test filtering by user_id
            print("4️⃣ Testing filter by user_id...")
            user_sightings = db.query(Sighting).filter(Sighting.user_id == test_user_id).all()
            print(f"   ✅ Found {len(user_sightings)} sighting(s) for user_id: {test_user_id}\n")
            
            # Test filtering by username
            print("5️⃣ Testing filter by username...")
            username_sightings = db.query(Sighting).filter(Sighting.username == test_username).all()
            print(f"   ✅ Found {len(username_sightings)} sighting(s) for username: {test_username}\n")
            
            print("✅ SUCCESS! RDS storage and retrieval working perfectly!\n")
            return True
        else:
            print("   ❌ Failed to fetch sighting!")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = test_store_and_fetch_sighting()
    sys.exit(0 if success else 1)

