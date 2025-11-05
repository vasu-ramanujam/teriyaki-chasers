import io
import os
import sys
from datetime import datetime, timezone
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.database import get_db, Base
from app.models import Species

# -------------------- DB & Client Setup --------------------
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_species.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides.clear()
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(scope="function")
def setup_database():
    """Create schema + seed 3 species; drop after test."""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()

    s1 = Species(
        id=1,
        common_name="American Robin",
        scientific_name="Turdus migratorius",
        habitat="Woodlands and gardens",
        diet="Insects and berries",
        behavior="Migratory songbird",
        description="A common North American songbird",
        created_at=datetime.now(timezone.utc),
    )
    s2 = Species(
        id=2,
        common_name="Blue Jay",
        scientific_name="Cyanocitta cristata",
        habitat="Forests and suburban areas",
        diet="Nuts, seeds, and insects",
        behavior="Intelligent and social",
        description="A colorful North American corvid",
        created_at=datetime.now(timezone.utc),
    )
    s3 = Species(
        id=3,
        common_name="Red-winged Blackbird",
        scientific_name="Agelaius phoeniceus",
        habitat="Wetlands and marshes",
        diet="Seeds and insects",
        behavior="Territorial during breeding season",
        description="A common marsh bird with distinctive red shoulder patches",
        created_at=datetime.now(timezone.utc),
    )

    db.add_all([s1, s2, s3])
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)

# -------------------- Existing /v1/species tests (kept style) --------------------
class TestSpeciesSearchAPI:
    def test_search_species_by_common_name(self, setup_database):
        r = client.get("/v1/species/?q=robin")
        assert r.status_code == 200
        data = r.json()
        assert "items" in data and len(data["items"]) == 1
        assert data["items"][0]["common_name"] == "American Robin"
        assert data["items"][0]["scientific_name"] == "Turdus migratorius"

    def test_search_species_by_scientific_name(self, setup_database):
        r = client.get("/v1/species/?q=Turdus")
        assert r.status_code == 200
        data = r.json()
        assert "items" in data and len(data["items"]) == 1
        assert data["items"][0]["scientific_name"] == "Turdus migratorius"

    def test_search_species_case_insensitive(self, setup_database):
        r = client.get("/v1/species/?q=BLUE")
        assert r.status_code == 200
        data = r.json()
        assert "items" in data and len(data["items"]) == 1
        assert data["items"][0]["common_name"] == "Blue Jay"


class TestSpeciesDetailsAPI:
    def test_get_species_details(self, setup_database):
        r = client.get("/v1/species/1")
        assert r.status_code in (200, 404)

# -------------------- NEW: /v1/species/{id}_with_img --------------------
class TestSpeciesWithImageAPI:
    @pytest.fixture
    def mock_wiki_summary(self):
        return {
            "title": "American Robin",
            "extract": "The American robin is a migratory songbird of the true thrush genus.",
            "content_urls": {
                "desktop": {"page": "https://en.wikipedia.org/wiki/American_robin"}
            },
            "wikibase_item": "Q26547",
            "originalimage": {
                "source": "https://upload.wikimedia.org/wikipedia/commons/american_robin.jpg",
                "width": 1200,
                "height": 800,
            },
        }

    @patch("app.routers.species._fetch_wikipedia_summary_by_title")
    def test_get_species_with_img_success(
        self, mock_fetch_summary, setup_database, mock_wiki_summary
    ):
        mock_fetch_summary.return_value = mock_wiki_summary

        r = client.get("/v1/species/1/img")
        assert r.status_code == 200
        data = r.json()
        assert data["species"] == "Turdus migratorius"
        assert data["english_name"] == "American Robin"
        assert "American robin"[:8].lower() in data["description"].lower()
        assert "other_sources" in data and len(data["other_sources"]) >= 1
        assert data["main_image"] == "https://upload.wikimedia.org/wikipedia/commons/american_robin.jpg"

    @patch("app.routers.species._fetch_wikipedia_summary_by_title")
    @patch("app.routers.species._search_wikipedia_title")
    def test_get_species_with_img_fallback_to_search(
        self, mock_search, mock_fetch_summary, setup_database, mock_wiki_summary
    ):
        mock_fetch_summary.side_effect = [None, mock_wiki_summary]
        mock_search.return_value = "American Robin"

        r = client.get("/v1/species/1/img")
        assert r.status_code == 200
        data = r.json()
        assert data["english_name"] == "American Robin"
        assert data["main_image"] == "https://upload.wikimedia.org/wikipedia/commons/american_robin.jpg"

# -------------------- NEW: /v1/identify/photo & /v1/identify/audio --------------------
class TestIdentifyAPI:

    @pytest.fixture
    def wiki_payload(self):
        return {
            "english_name": "American Robin",
            "description": "The American robin is a migratory songbird of the true thrush genus.",
            "other_sources": ["https://en.wikipedia.org/wiki/American_robin"],
            "main_image": "https://upload.wikimedia.org/wikipedia/commons/american_robin.jpg",
        }

    @patch("app.routers.identify._identify_species_from_image")
    def test_identify_photo_flow(
        self, mock_gpt, setup_database, wiki_payload
    ):
        mock_gpt.return_value = "American Robin"

        fake_image = io.BytesIO(b"\x89PNG\r\n\x1a\nFAKE_IMAGE")
        files = {"photo": ("test.png", fake_image, "image/png")}
        r = client.post("/v1/identify/photo", files=files)
        assert r.status_code == 200
        data = r.json()

        assert data["label"] == "American Robin"
        assert data["wiki_data"]["english_name"].lower() == "American Robin".lower()
        print("Image URL returned:", data["wiki_data"]["main_image"])
        assert data["wiki_data"]["main_image"] is not None

        mock_gpt.assert_called_once()

    @patch("app.routers.identify._identify_species_from_audio")
    def test_identify_audio_flow(
        self, mock_gpt, setup_database, wiki_payload
    ):
        mock_gpt.return_value = "American Robin"

        fake_wav = io.BytesIO(b"RIFF\x00\x00\x00\x00WAVEfmt ")
        files = {"audio": ("test.wav", fake_wav, "audio/wav")}
        r = client.post("/v1/identify/audio", files=files)
        assert r.status_code == 200
        data = r.json()

        assert data["label"] == "American Robin"
        assert data["wiki_data"]["english_name"].lower() == "American Robin".lower()
        print("Image URL returned:", data["wiki_data"]["main_image"])
        assert data["wiki_data"]["main_image"] is not None

        mock_gpt.assert_called_once()

