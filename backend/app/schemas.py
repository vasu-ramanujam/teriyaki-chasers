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
    id: int
    habitat: Optional[str] = None
    diet: Optional[str] = None
    behavior: Optional[str] = None
    description: Optional[str] = None
    other_sources: Optional[List[str]] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

class SpeciesDetail(BaseModel):
    """Species detail response for GET /v1/species/{name}"""
    species: str  # Scientific name
    english_name: str  # Common name
    description: Optional[str] = None
    other_sources: Optional[List[str]] = None

class SpeciesDetails(BaseModel):
    """Enhanced species details with Wikipedia integration"""
    species: str  # scientific name or common name
    english_name: Optional[str] = None  # common name from Wikipedia
    description: Optional[str] = None  # description from Wikipedia
    other_sources: List[str] = []  # Wikipedia and Wikidata links
    main_image: Optional[str] = None  # main image URL from Wikipedia

    class Config:
        from_attributes = True

class SpeciesSearch(BaseModel):
    items: List[Species]

# Sighting schemas
class SightingBase(BaseModel):
    species_id: int
    lat: float
    lon: float
    taken_at: datetime
    is_private: bool = False

class SightingCreate(SightingBase):
    media_url: Optional[str] = None

class Sighting(SightingBase):
    id: str
    username: Optional[str] = None
    media_thumb_url: Optional[str] = None
    media_url: Optional[str] = None
    caption: Optional[str] = None
    created_at: datetime
    taken_at: datetime
    
    class Config:
        from_attributes = True

class SightingDetail(BaseModel):
    """Sighting detail response for GET /v1/sightings/{id}"""
    id: int
    species: str  # Species observed (scientific name)
    location: str  # Location of sighting (lat,lon format)
    time: str  # Time of sighting (ISO format)
    username: str  # User's display name
    is_private: bool  # Whether the post is private or public
    caption: Optional[str] = None  # Optional caption

class SightingList(BaseModel):
    items: List[Sighting]

class SightingFilter(BaseModel):
    area: Optional[str] = None
    species_id: Optional[int] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    username: Optional[str] = None

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

class FlashcardInfo(BaseModel):
    species_name: str
    first_seen: datetime
    num_sightings: int

class UserStats(BaseModel):
    username: str
    total_sightings: int
    total_species: int
    flashcards: List[FlashcardInfo]

    class Config:
        orm_mode = True
