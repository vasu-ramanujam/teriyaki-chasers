"""
Fixtures and configuration for tests
"""
import pytest
import os

# Set testing flag before any app imports
os.environ["TESTING"] = "1"

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from app.database import Base, get_db
from app.main import app
from app.models import Species, Sighting
import uuid
from datetime import datetime

# Use in-memory SQLite database for testing
TEST_DATABASE_URL = "sqlite:///./test_animal_explorer.db"

@pytest.fixture(scope="function")
def test_db():
    """Create a test database for each test function"""
    engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    # Create a test session
    db = TestingSessionLocal()
    
    try:
        yield db
    finally:
        db.close()
        # Drop all tables after the test
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(test_db):
    """Create a test client with the test database"""
    def override_get_db():
        try:
            yield test_db
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()

@pytest.fixture
def sample_species(test_db):
    """Create a sample species for testing"""
    species = Species(
        id=str(uuid.uuid4()),
        common_name="Test Bird",
        scientific_name="Testus birdus",
        habitat="Test habitat",
        diet="Test diet",
        behavior="Test behavior"
    )
    test_db.add(species)
    test_db.commit()
    test_db.refresh(species)
    return species

@pytest.fixture
def sample_sighting(test_db, sample_species):
    """Create a sample sighting for testing"""
    sighting = Sighting(
        id=str(uuid.uuid4()),
        user_id="test_user_123",
        species_id=sample_species.id,
        lat=37.7749,
        lon=-122.4194,
        taken_at=datetime(2024, 1, 15, 10, 30, 0),
        is_private=False,
        media_url="/uploads/test_image.jpg",
        notes="Initial test notes"
    )
    test_db.add(sighting)
    test_db.commit()
    test_db.refresh(sighting)
    return sighting

@pytest.fixture
def sample_sighting_no_notes(test_db, sample_species):
    """Create a sample sighting without notes for testing"""
    sighting = Sighting(
        id=str(uuid.uuid4()),
        user_id="test_user_456",
        species_id=sample_species.id,
        lat=40.7128,
        lon=-74.0060,
        taken_at=datetime(2024, 2, 20, 14, 45, 0),
        is_private=False,
        media_url="/uploads/test_image2.jpg",
        notes=None
    )
    test_db.add(sighting)
    test_db.commit()
    test_db.refresh(sighting)
    return sighting
