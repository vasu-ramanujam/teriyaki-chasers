#!/usr/bin/env python3
"""
Migration script to add notes column to sightings table if it doesn't exist.
Run this script to update the database schema.
"""

import os
import sys
from sqlalchemy import text
from app.database import engine, get_db

def add_notes_column():
    """Add notes column to sightings table if it doesn't exist."""
    try:
        with engine.connect() as connection:
            # Check if notes column exists
            result = connection.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'sightings' AND column_name = 'notes'
            """))
            
            if result.fetchone() is None:
                print("Adding notes column to sightings table...")
                connection.execute(text("ALTER TABLE sightings ADD COLUMN notes TEXT"))
                connection.commit()
                print("✓ Notes column added successfully!")
            else:
                print("✓ Notes column already exists.")
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("Running migration to add notes column...")
    add_notes_column()
    print("Migration completed!")