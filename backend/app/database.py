from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Get the database URL (prioritizes RDS if configured)
database_url = settings.get_database_url()

# Configure engine with connection pooling for RDS
# SQLite doesn't support pooling, so we only use it for PostgreSQL
if database_url.startswith("postgresql"):
    engine = create_engine(
        database_url,
        poolclass=QueuePool,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_timeout=settings.db_pool_timeout,
        pool_recycle=settings.db_pool_recycle,
        echo=False,  # Set to True for SQL query logging
        connect_args={
            "connect_timeout": 10,
            "options": "-c statement_timeout=30000",  # 30 second statement timeout
            "sslmode": "require"  # Require SSL encryption for RDS
        }
    )
    logger.info("Initialized PostgreSQL database engine with connection pooling")
else:
    # SQLite (local development) - no pooling needed
    engine = create_engine(
        database_url,
        echo=False,
        connect_args={"check_same_thread": False} if database_url.startswith("sqlite") else {}
    )
    logger.info("Initialized SQLite database engine")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency function for FastAPI to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def test_connection():
    """Test database connection"""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Database connection successful")
        return True
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return False

