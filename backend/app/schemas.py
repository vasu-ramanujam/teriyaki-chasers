from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# Species schemas
class SpeciesBase(BaseModel):
    common_name: str
    scientific_name: str

class SpeciesCreate(SpeciesBase):
    pass

class Species(SpeciesBase):
    id: str
    habitat: Optional[str] = None
    diet: Optional[str] = None
    behavior: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

class SpeciesSearch(BaseModel):
    items: List[Species]

# Sighting schemas
class SightingBase(BaseModel):
    species_id: str
    lat: float
    lon: float
    taken_at: datetime
    is_private: bool = False

class SightingCreate(SightingBase):
    media_url: Optional[str] = None

class Sighting(SightingBase):
    id: str
    user_id: Optional[str] = None
    username: Optional[str] = None
    media_thumb_url: Optional[str] = None
    audio_url: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

class SightingUpdate(BaseModel):
    location: Optional[str] = None  # Format: "lat,lon"
    time: Optional[str] = None      # ISO8601 datetime string
    notes: Optional[str] = None

class SightingList(BaseModel):
    items: List[Sighting]

# Route schemas
class RoutePoint(BaseModel):
    lat: float
    lon: float

class RouteCreate(BaseModel):
    start: RoutePoint
    end: RoutePoint

class Route(BaseModel):
    id: str
    provider: str
    polyline: str
    distance_m: float
    duration_s: float
    
    class Config:
        from_attributes = True

class RouteWaypoint(BaseModel):
    lat: float
    lon: float
    sighting_id: Optional[str] = None

class RouteAugment(BaseModel):
    waypoints: List[RouteWaypoint]
    max_extra_duration_s: Optional[int] = 900

class SightingNearRoute(BaseModel):
    sighting_id: str
    species_id: str
    lat: float
    lon: float
    detour_cost_s: int

class SightingNearRouteList(BaseModel):
    items: List[SightingNearRoute]

# Identification schemas
class IdentificationCandidate(BaseModel):
    species_id: str
    label: str
    score: float

class IdentificationResult(BaseModel):
    candidates: List[IdentificationCandidate]

# Error schema
class ErrorResponse(BaseModel):
    error: str
    code: str

