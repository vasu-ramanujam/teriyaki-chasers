from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "sqlite:///./animal_explorer.db"
    mapbox_access_token: Optional[str] = None
    directions_provider: str = "mapbox"
    api_base_url: str = "http://127.0.0.1:8000"
    
    # AI/ML API Keys (optional for development)
    openai_api_key: Optional[str] = None
    inaturalist_api_key: Optional[str] = None
    birdweather_api_key: Optional[str] = None
    
    class Config:
        env_file = ".env"

settings = Settings()

