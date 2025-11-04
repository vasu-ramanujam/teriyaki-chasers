#!/usr/bin/env python3
"""
Test RDS database connection
"""
import sys
from app.database import engine, test_connection
from app.config import settings

def test_rds_setup():
    """Test RDS connection and configuration"""
    print("🧪 Testing RDS Database Connection\n")
    
    database_url = settings.get_database_url()
    
    # Check configuration
    print("📋 Configuration Check:")
    if database_url.startswith("postgresql"):
        print(f"✅ Using PostgreSQL database")
        if settings.rds_host:
            print(f"   Host: {settings.rds_host}")
            print(f"   Port: {settings.rds_port}")
            print(f"   Database: {settings.rds_database}")
            print(f"   Username: {settings.rds_username}")
            print(f"   Pool Size: {settings.db_pool_size}")
        else:
            print(f"   Connection String: {database_url.split('@')[1] if '@' in database_url else 'configured'}")
    else:
        print(f"⚠️  Not using RDS PostgreSQL")
        print(f"   Current database: {database_url}")
        print("\n   To use RDS, set these in .env:")
        print("   - RDS_HOST")
        print("   - RDS_USERNAME")
        print("   - RDS_PASSWORD")
        print("   - RDS_DATABASE")
        return False
    
    print("\n🔌 Connection Test:")
    try:
        if test_connection():
            print("✅ Connection successful!\n")
            
            # Test a simple query
            print("📊 Database Status:")
            from app.database import SessionLocal
            from app.models import Species, Sighting
            from sqlalchemy import text
            
            db = SessionLocal()
            try:
                # Get table counts
                species_count = db.query(Species).count()
                sightings_count = db.query(Sighting).count()
                
                print(f"   Species table: {species_count} records")
                print(f"   Sightings table: {sightings_count} records")
                
                if species_count == 0:
                    print("\n   ⚠️  Database is empty. Run: python3 init_rds_db.py --seed")
                
            except Exception as e:
                print(f"   ⚠️  Error querying tables: {e}")
                print("   This might be normal if tables don't exist yet.")
                print("   Run: python3 init_rds_db.py --seed")
            finally:
                db.close()
            
            return True
        else:
            print("❌ Connection failed")
            return False
            
    except Exception as e:
        print(f"❌ Connection error: {e}")
        print("\nTroubleshooting:")
        print("1. Check your RDS endpoint, username, and password in .env")
        print("2. Verify security group allows connections from your IP")
        print("3. Ensure RDS instance is running and accessible")
        return False

if __name__ == "__main__":
    success = test_rds_setup()
    sys.exit(0 if success else 1)

