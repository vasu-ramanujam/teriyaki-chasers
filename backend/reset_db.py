#!/usr/bin/env python3
"""
Reset the database with the new schema
"""
import psycopg2
from sqlalchemy import create_engine, text
from app.config import settings
from app.database import engine, Base
from app.models import Species, Sighting, Route, RouteWaypoint

def reset_database():
    """Drop and recreate the database with new schema"""
    try:
        # Parse the database URL to get connection details
        db_url = settings.database_url
        if db_url.startswith('postgresql+psycopg2://'):
            # Extract connection details
            url_parts = db_url.replace('postgresql+psycopg2://', '').split('/')
            if len(url_parts) >= 2:
                db_name = url_parts[1]
                host_port = url_parts[0]
                
                # Connect to PostgreSQL server (not specific database)
                if '@' in host_port:
                    # Has username:password
                    auth, host_port = host_port.split('@')
                    if ':' in auth:
                        username, password = auth.split(':')
                    else:
                        username, password = auth, ''
                else:
                    username, password = 'postgres', ''
                
                if ':' in host_port:
                    host, port = host_port.split(':')
                else:
                    host, port = host_port, '5432'
                
                # Connect to postgres database to drop/create our database
                conn = psycopg2.connect(
                    host=host,
                    port=port,
                    user=username,
                    password=password,
                    database='postgres'
                )
                conn.autocommit = True
                cursor = conn.cursor()
                
                # Drop database if it exists
                cursor.execute(f"DROP DATABASE IF EXISTS {db_name}")
                print(f"Dropped database: {db_name}")
                
                # Create new database
                cursor.execute(f"CREATE DATABASE {db_name}")
                print(f"Created database: {db_name}")
                
                cursor.close()
                conn.close()
                
                # Now create tables with new schema
                Base.metadata.create_all(bind=engine)
                print("Created tables with new schema")
                
                return True
                
    except Exception as e:
        print(f"Error resetting database: {e}")
        return False

if __name__ == "__main__":
    if reset_database():
        print("✅ Database reset successfully!")
        print("Now run: python3 init_db.py")
    else:
        print("❌ Failed to reset database")




