#!/usr/bin/env python3
"""
Script to remove sightings from RDS that have both null media_url and audio_url
"""

import sys
from app.database import SessionLocal
from app.models import Sighting
from sqlalchemy import and_
from app.config import settings

def remove_sightings_without_media(auto_confirm=False):
    """Remove sightings where both media_url and audio_url are null"""
    
    print("=" * 60)
    print("Removing Sightings Without Media")
    print("=" * 60)
    print()
    
    # Check if using RDS
    database_url = settings.get_database_url()
    is_rds = database_url.startswith("postgresql")
    
    if not is_rds:
        print("⚠️  Warning: Not connected to RDS (PostgreSQL)")
        print(f"   Current database: {database_url.split('://')[0]}")
        print()
        return False
    
    print("✅ Connected to RDS PostgreSQL")
    print()
    
    db = SessionLocal()
    
    try:
        # First, count how many sightings will be deleted
        print("📊 Checking sightings...")
        count_query = db.query(Sighting).filter(
            and_(
                Sighting.media_url.is_(None),
                Sighting.audio_url.is_(None)
            )
        )
        count = count_query.count()
        
        print(f"   Found {count} sightings with both null media_url and audio_url")
        print()
        
        if count == 0:
            print("✅ No sightings to delete. All sightings have at least one media URL.")
            return True
        
        # Show a preview (first 5)
        print("📋 Preview of sightings to be deleted (first 5):")
        preview_sightings = count_query.limit(5).all()
        for sighting in preview_sightings:
            print(f"   - ID: {sighting.id}")
            print(f"     Species ID: {sighting.species_id}")
            print(f"     Location: {sighting.lat}, {sighting.lon}")
            print(f"     Created: {sighting.created_at}")
            print()
        
        # Ask for confirmation
        print(f"⚠️  This will permanently delete {count} sighting(s).")
        
        if not auto_confirm:
            try:
                response = input("Are you sure you want to proceed? (yes/no): ").strip().lower()
                if response != 'yes':
                    print("❌ Deletion cancelled.")
                    return False
            except (EOFError, KeyboardInterrupt):
                print("\n❌ Deletion cancelled.")
                return False
        else:
            print("ℹ️  Auto-confirm mode: Proceeding with deletion...")
        
        print()
        print("🗑️  Deleting sightings...")
        
        # Delete the sightings
        deleted_count = count_query.delete(synchronize_session=False)
        db.commit()
        
        print(f"✅ Successfully deleted {deleted_count} sighting(s)")
        print()
        
        # Verify deletion
        remaining_count = db.query(Sighting).filter(
            and_(
                Sighting.media_url.is_(None),
                Sighting.audio_url.is_(None)
            )
        ).count()
        
        if remaining_count == 0:
            print("✅ Verification: All sightings without media have been removed.")
        else:
            print(f"⚠️  Warning: {remaining_count} sightings still have null media URLs.")
        
        # Show total remaining sightings
        total_remaining = db.query(Sighting).count()
        print(f"📊 Total sightings remaining: {total_remaining}")
        
        return True
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    import sys
    
    # Check for auto-confirm flag
    auto_confirm = '--auto-confirm' in sys.argv or '--yes' in sys.argv
    
    try:
        success = remove_sightings_without_media(auto_confirm=auto_confirm)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n❌ Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

