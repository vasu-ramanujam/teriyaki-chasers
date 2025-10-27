from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://xinggeli@localhost:5432/animal_explorer"
    mapbox_access_token: Optional[str] = None
    directions_provider: str = "mapbox"
    api_base_url: str = "http://127.0.0.1:8000"
    
    # Storage settings
    storage_type: str = "local"  # "local" or "s3"
    upload_directory: str = "uploads"
    
    # S3 settings (if storage_type is "s3")
    s3_bucket_name: Optional[str] = None
    s3_access_key: Optional[str] = None
    s3_secret_key: Optional[str] = None
    s3_region: Optional[str] = "us-east-1"
    s3_endpoint_url: Optional[str] = None  # For S3-compatible services
    
    # CDN settings (optional for optimized delivery)
    cdn_domain: Optional[str] = None  # e.g., "d123456.cloudfront.net"
    
    class Config:
        env_file = ".env"

settings = Settings()

