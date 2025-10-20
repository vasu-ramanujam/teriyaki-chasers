from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from geoalchemy2 import functions as geo_func
from typing import List
import requests
import polyline
from app.database import get_db
from app.models import Route, RouteWaypoint, Sighting
from app.schemas import RouteCreate, Route, RouteAugment, SightingNearRouteList, SightingNearRoute
from app.config import settings

router = APIRouter()

def call_directions_api(start_lat: float, start_lon: float, end_lat: float, end_lon: float):
    """Call external directions API (Mapbox or similar)"""
    if settings.directions_provider == "mapbox" and settings.mapbox_access_token:
        url = "https://api.mapbox.com/directions/v5/mapbox/driving"
        params = {
            "access_token": settings.mapbox_access_token,
            "geometries": "polyline6",
            "overview": "full"
        }
        coordinates = f"{start_lon},{start_lat};{end_lon},{end_lat}"
        
        response = requests.get(f"{url}/{coordinates}", params=params)
        if response.status_code == 200:
            data = response.json()
            route = data["routes"][0]
            return {
                "polyline": route["geometry"],
                "distance_m": route["distance"],
                "duration_s": route["duration"]
            }
    
    # Fallback to simple straight-line calculation
    return {
        "polyline": polyline.encode([(start_lat, start_lon), (end_lat, end_lon)]),
        "distance_m": 1000,  # Placeholder
        "duration_s": 600    # Placeholder
    }

@router.post("/", response_model=Route)
async def create_route(
    route_data: RouteCreate,
    db: Session = Depends(get_db)
):
    """Create a route from start to end point"""
    try:
        # Call directions API
        directions = call_directions_api(
            route_data.start.lat, route_data.start.lon,
            route_data.end.lat, route_data.end.lon
        )
        
        # Store route in database
        route = Route(
            start_lat=route_data.start.lat,
            start_lon=route_data.start.lon,
            end_lat=route_data.end.lat,
            end_lon=route_data.end.lon,
            provider=settings.directions_provider,
            distance_m=directions["distance_m"],
            duration_s=directions["duration_s"],
            polyline=directions["polyline"]
        )
        
        db.add(route)
        db.commit()
        db.refresh(route)
        
        return route
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/sightings-near", response_model=SightingNearRouteList)
async def get_sightings_near_route(
    route_id: str = Query(...),
    radius_m: int = Query(200, ge=50, le=1000),
    db: Session = Depends(get_db)
):
    """Find sightings near a route"""
    try:
        # Get route
        route = db.query(Route).filter(Route.id == route_id).first()
        if not route:
            raise HTTPException(status_code=404, detail="Route not found")
        
        # Decode polyline to get route geometry
        try:
            decoded_coords = polyline.decode(route.polyline)
            if not decoded_coords:
                return SightingNearRouteList(items=[])
        except:
            # Fallback to start/end points
            decoded_coords = [
                (route.start_lat, route.start_lon),
                (route.end_lat, route.end_lon)
            ]
        
        # Create route line geometry
        coords_str = ",".join([f"{lon} {lat}" for lat, lon in decoded_coords])
        route_line = f"LINESTRING({coords_str})"
        
        # Find sightings within radius of route
        query = db.query(Sighting).filter(
            geo_func.ST_DWithin(
                Sighting.geom,
                geo_func.ST_GeomFromText(route_line, 4326),
                radius_m
            )
        ).limit(20)
        
        sightings = query.all()
        
        # Convert to response format
        items = []
        for sighting in sightings:
            # Calculate detour cost (simplified)
            detour_cost_s = 180  # Placeholder calculation
            
            items.append(SightingNearRoute(
                sighting_id=sighting.id,
                species_id=sighting.species_id,
                lat=float(sighting.geom.data.split()[1]),  # Extract lat from POINT
                lon=float(sighting.geom.data.split()[0]),  # Extract lon from POINT
                detour_cost_s=detour_cost_s
            ))
        
        return SightingNearRouteList(items=items)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{route_id}/augment", response_model=Route)
async def augment_route(
    route_id: str,
    augment_data: RouteAugment,
    db: Session = Depends(get_db)
):
    """Augment route with additional waypoints"""
    try:
        # Get original route
        route = db.query(Route).filter(Route.id == route_id).first()
        if not route:
            raise HTTPException(status_code=404, detail="Route not found")
        
        # Create waypoints
        for i, waypoint in enumerate(augment_data.waypoints):
            route_waypoint = RouteWaypoint(
                route_id=route_id,
                seq=i,
                lat=waypoint.lat,
                lon=waypoint.lon,
                sighting_id=waypoint.sighting_id
            )
            db.add(route_waypoint)
        
        # For now, return the original route
        # In a full implementation, you'd recalculate the route with waypoints
        db.commit()
        
        return route
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

