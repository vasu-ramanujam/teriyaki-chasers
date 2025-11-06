from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from dotenv import load_dotenv

from app.routers import species, sightings, routing, identify, user
from app.database import engine, Base
from app.config import settings

load_dotenv()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Animal Explorer API",
    description="Backend API for Animal Explorer iOS app",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only - restrict in production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include routers
app.include_router(species.router, prefix="/v1/species", tags=["species"])
app.include_router(sightings.router, prefix="/v1/sightings", tags=["sightings"])
app.include_router(routing.router, prefix="/v1/route", tags=["routing"])
app.include_router(identify.router, prefix="/v1/identify", tags=["identify"])
app.include_router(user.router, prefix="/v1/user", tags=["user"])

@app.get("/")
async def root():
    return {"message": "Animal Explorer API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

