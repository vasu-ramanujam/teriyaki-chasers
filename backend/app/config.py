from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database Configuration
    # For SQLite (local dev): sqlite:///./animal_explorer.db
    # For RDS PostgreSQL: postgresql+psycopg2://username:password@host:port/database
    database_url: str = "sqlite:///./animal_explorer.db"
    
    # RDS-specific settings (if using RDS)
    rds_host: Optional[str] = None
    rds_port: int = 5432
    rds_database: Optional[str] = None
    rds_username: Optional[str] = None
    rds_password: Optional[str] = None
    
    # Connection pool settings for RDS
    db_pool_size: int = 5
    db_max_overflow: int = 10
    db_pool_timeout: int = 30
    db_pool_recycle: int = 3600
    
    mapbox_access_token: Optional[str] = None
    directions_provider: str = "mapbox"
    api_base_url: str = "http://127.0.0.1:8000"
    
    # AI/ML API Keys (optional for development)
    openai_api_key: Optional[str] = None
    inaturalist_api_key: Optional[str] = None
    birdweather_api_key: Optional[str] = None
    
    # AWS S3 Configuration
    # Load from environment variables - never hardcode credentials!
    aws_access_key_id: Optional[str] = None
    aws_secret_access_key: Optional[str] = None
    aws_region: str = "us-east-2"
    aws_s3_bucket_name: Optional[str] = "teriyaki-chasers-wildlife-media"
    
    def get_database_url(self) -> str:
        """Build database URL, preferring RDS if configured"""
        # Use RDS credentials from environment variables or settings
        rds_host = self.rds_host or "wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com"
        rds_port = self.rds_port
        rds_database = self.rds_database or "animal_explorer"
        rds_username = self.rds_username or "wildlife_admin"
        rds_password = self.rds_password
        
        if not rds_password:
            raise ValueError("RDS password must be provided via environment variable or .env file")
        
        # Build RDS connection string
        return f"postgresql+psycopg2://{rds_username}:{rds_password}@{rds_host}:{rds_port}/{rds_database}"
    
    class Config:
        env_file = ".env"

settings = Settings()

