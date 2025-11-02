from sqlalchemy import Column, String, DateTime, Boolean, Float, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
import os

# Only import and use Geometry if not in testing mode
TESTING = os.getenv("TESTING", "0") == "1"
if not TESTING:
    from geoalchemy2 import Geometry

from app.database import Base
import uuid
from datetime import datetime

class Species(Base):
    __tablename__ = "species"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    common_name = Column(String, nullable=False)
    scientific_name = Column(String, nullable=False)
    habitat = Column(Text, nullable=True)
    diet = Column(Text, nullable=True)
    behavior = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    sightings = relationship("Sighting", back_populates="species")

class Sighting(Base):
    __tablename__ = "sightings"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=True)  # NULL for anonymous (auth ID)
    username = Column(String, nullable=True)  # Display name like "Ada" or "birdwatcher1"
    species_id = Column(Integer, ForeignKey("species.id"), nullable=False)
    lat = Column(Float, nullable=False)  # Latitude
    lon = Column(Float, nullable=False)  # Longitude
    taken_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    is_private = Column(Boolean, nullable=False, default=False)
    media_url = Column(String, nullable=True)  # Photo URL (S3)
    audio_url = Column(String, nullable=True)  # Audio recording URL (S3)
    caption = Column(Text, nullable=True)  # User caption about the sighting (RDS uses 'caption' not 'notes')
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    species = relationship("Species", back_populates="sightings")
    route_waypoints = relationship("RouteWaypoint", back_populates="sighting")

class Route(Base):
    __tablename__ = "routes"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=True)
    start_lat = Column(Float, nullable=False)
    start_lon = Column(Float, nullable=False)
    end_lat = Column(Float, nullable=False)
    end_lon = Column(Float, nullable=False)
    provider = Column(String, nullable=False)
    distance_m = Column(Float, nullable=False)
    duration_s = Column(Float, nullable=False)
    polyline = Column(Text, nullable=True)  # Encoded polyline
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    waypoints = relationship("RouteWaypoint", back_populates="route")

class RouteWaypoint(Base):
    __tablename__ = "route_waypoints"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    route_id = Column(String, ForeignKey("routes.id"), nullable=False)
    seq = Column(Integer, nullable=False)
    lat = Column(Float, nullable=False)
    lon = Column(Float, nullable=False)
    sighting_id = Column(String, ForeignKey("sightings.id"), nullable=True)
    
    # Relationships
    route = relationship("Route", back_populates="waypoints")
    sighting = relationship("Sighting", back_populates="route_waypoints")

