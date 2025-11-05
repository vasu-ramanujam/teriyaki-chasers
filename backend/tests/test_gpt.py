import os
import io
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

@pytest.mark.skipif(
    not os.getenv("OPENAI_API_KEY"),
    reason="❌ Skipped because no OPENAI_API_KEY is set in environment."
)
class TestRealGPTIdentifyAPI:
    def test_real_identify_photo(self):
        with open("backend/tests/assets/american_robin.jpg", "rb") as f:
            files = {"photo": ("test.jpg", f, "image/jpeg")}

            resp = client.post("/v1/identify/photo", files=files)

        print("\n📸 Real GPT Photo Response:", resp.json())
        assert resp.status_code == 200

        data = resp.json()
        assert "label" in data
        assert "wiki_data" in data
        assert data["wiki_data"]["english_name"] != ""
        assert data["wiki_data"]["main_image"] is not None

