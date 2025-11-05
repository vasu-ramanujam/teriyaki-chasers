from sqlalchemy import Column, String, DateTime, Boolean, Float, Integer, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from app.database import Base
import uuid
from datetime import datetime

class Species(Base):
    __tablename__ = "species"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    common_name = Column(String, nullable=True)
    scientific_name = Column(String, nullable=True)
    habitat = Column(Text, nullable=True)
    diet = Column(Text, nullable=True)
    behavior = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    other_sources = Column(JSON, nullable=True)  # Array of links to other references
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    sightings = relationship("Sighting", back_populates="species")

class Sighting(Base):
    __tablename__ = "sightings"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    username = Column(String, nullable=True)  # User's display name
    species_id = Column(Integer, ForeignKey("species.id"), nullable=False)
    lat = Column(Float, nullable=False)  # Latitude
    lon = Column(Float, nullable=False)  # Longitude
    taken_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    is_private = Column(Boolean, nullable=False, default=False)
    media_url = Column(String, nullable=True)
    caption = Column(Text, nullable=True)  # Optional caption
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    species = relationship("Species", back_populates="sightings")
    route_waypoints = relationship("RouteWaypoint", back_populates="sighting")
    user = relationship("User", back_populates="sightings")

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

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False)

    sightings = relationship("Sighting", back_populates="user")
