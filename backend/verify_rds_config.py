#!/usr/bin/env python3
"""
Verify and test RDS configuration
"""
import os
from dotenv import load_dotenv

# Force reload .env
load_dotenv(override=True)

print("🔍 Checking RDS Configuration...\n")

rds_vars = {
    'RDS_HOST': os.getenv('RDS_HOST'),
    'RDS_PORT': os.getenv('RDS_PORT', '5432'),
    'RDS_DATABASE': os.getenv('RDS_DATABASE'),
    'RDS_USERNAME': os.getenv('RDS_USERNAME'),
    'RDS_PASSWORD': os.getenv('RDS_PASSWORD')
}

print("📋 Environment Variables from .env:\n")
all_set = True
for key, value in rds_vars.items():
    if value:
        if key == 'RDS_PASSWORD':
            print(f"✅ {key}: {'*' * min(len(value), 10)}")
        else:
            print(f"✅ {key}: {value}")
    else:
        print(f"❌ {key}: Not set")
        all_set = False

if not all_set:
    print("\n⚠️  Missing RDS configuration. Please check your .env file.")
    print("\nRequired variables:")
    print("  RDS_HOST=your-rds-endpoint.rds.amazonaws.com")
    print("  RDS_PORT=5432")
    print("  RDS_DATABASE=animal_explorer")
    print("  RDS_USERNAME=your_username")
    print("  RDS_PASSWORD=your_password")
    exit(1)

print("\n🔌 Testing Connection...\n")

try:
    from app.config import settings
    from app.database import test_connection, engine
    
    db_url = settings.get_database_url()
    if db_url.startswith("postgresql"):
        print(f"✅ Using RDS PostgreSQL")
        print(f"   Host: {settings.rds_host}")
        print(f"   Database: {settings.rds_database}\n")
        
        if test_connection():
            print("✅ SUCCESS! RDS connection is working!\n")
            
            # Check if tables exist
            from app.database import SessionLocal
            from app.models import Species, Sighting
            from sqlalchemy import inspect
            
            db = SessionLocal()
            try:
                inspector = inspect(engine)
                tables = inspector.get_table_names()
                
                print("📊 Database Status:")
                if 'species' in tables and 'sightings' in tables:
                    species_count = db.query(Species).count()
                    sightings_count = db.query(Sighting).count()
                    print(f"   ✅ Tables exist")
                    print(f"   Species: {species_count} records")
                    print(f"   Sightings: {sightings_count} records")
                    
                    if species_count == 0:
                        print("\n   💡 Tip: Run 'python3 init_rds_db.py --seed' to initialize tables and add sample data")
                else:
                    print(f"   ⚠️  Tables not found. Run 'python3 init_rds_db.py --seed' to create them")
                    print(f"   Found tables: {tables}")
                    
            except Exception as e:
                print(f"   ⚠️  Error checking tables: {e}")
            finally:
                db.close()
        else:
            print("❌ Connection failed. Check:")
            print("   1. RDS instance is running")
            print("   2. Security group allows connections from your IP")
            print("   3. Credentials are correct")
            exit(1)
    else:
        print(f"⚠️  Not using RDS. Current database: {db_url}")
        exit(1)
        
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    exit(1)


