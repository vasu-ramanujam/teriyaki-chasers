import os
import base64
from typing import Dict, Any, Optional
import httpx
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.routers.species import _enrich_with_wikipedia_with_image
from app.models import Species

router = APIRouter()

OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

OPENAI_IMAGE_MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-4o")
OPENAI_AUDIO_MODEL = os.getenv("OPENAI_AUDIO_MODEL", "gpt-4o")
OPENAI_TEXT_MODEL  = os.getenv("OPENAI_TEXT_MODEL", "gpt-4o-mini")

HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "30"))
DEFAULT_UA = "WildlifeExplorer/1.0 (contact: ios-app)"

def _require_api_key():
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=500, detail="Missing OPENAI_API_KEY environment variable")


def _get_or_create_species(db: Session, label: str, wiki_data: Optional[Dict[str, Any]]) -> Optional[int]:
    """Ensure we have a Species row for the identified label and return its id."""

    if not label:
        return None

    species = (
        db.query(Species)
        .filter(func.lower(Species.common_name) == label.lower())
        .first()
    )
    if species:
        return species.id

    scientific = label
    description = None
    other_sources = None

    if wiki_data:
        scientific = wiki_data.get("species") or scientific
        description = wiki_data.get("description")
        other_sources = wiki_data.get("other_sources")

    species = Species(
        common_name=label,
        scientific_name=scientific,
        description=description,
        other_sources=other_sources,
    )

    db.add(species)
    db.commit()
    db.refresh(species)
    return species.id

# ------------------ OpenAI ------------------

async def _identify_species_from_image(image_bytes: bytes) -> str:
    _require_api_key()
    b64 = base64.b64encode(image_bytes).decode("utf-8")

    url = f"{OPENAI_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": DEFAULT_UA,
    }
    messages = [{
        "role": "user",
        "content": [
            {"type": "text",
             "text": "Identify the wildlife species shown in this image. "
                     "Return ONLY the English common name (e.g., 'American Robin'). No extra words."},
            {"type": "image_url",
             "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}
        ]
    }]
    payload = {"model": OPENAI_IMAGE_MODEL, "messages": messages, "temperature": 0}

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"OpenAI image identify error: {r.text}")

    data = r.json()
    label = (data["choices"][0]["message"]["content"] or "").strip()
    if not label:
        raise HTTPException(status_code=502, detail="Empty label from OpenAI (image).")
    return label


async def _identify_species_from_audio(audio_bytes: bytes, fmt_hint: str = "wav") -> str:
    _require_api_key()
    b64 = base64.b64encode(audio_bytes).decode("utf-8")

    url = f"{OPENAI_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": DEFAULT_UA,
    }
    messages = [{
        "role": "user",
        "content": [
            {"type": "text",
             "text": "Identify the wildlife species from this audio (animal call). "
                     "Return ONLY the English common name (e.g., 'American Robin'). No extra words."},
            {"type": "input_audio",
             "input_audio": {"data": b64, "format": fmt_hint}}
        ]
    }]
    payload = {"model": OPENAI_AUDIO_MODEL, "messages": messages, "temperature": 0}

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"OpenAI audio identify error: {r.text}")

    data = r.json()
    label = (data["choices"][0]["message"]["content"] or "").strip()
    if not label:
        raise HTTPException(status_code=502, detail="Empty label from OpenAI (audio).")
    return label






# ------------------ FastAPI routes ------------------



@router.post("/photo")
async def identify_photo(
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    try:
        img = await photo.read()
        label = await _identify_species_from_image(img)
        wiki_data = await _enrich_with_wikipedia_with_image(label)
        species_id = _get_or_create_species(db, label, wiki_data)
        return {"label": label, "species_id": species_id, "wiki_data": wiki_data}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/audio")
async def identify_audio(
    audio: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    try:
        fmt_hint = "wav"
        if audio.content_type:
            ctype = audio.content_type.lower()
            if "/" in ctype:
                guess = ctype.split("/")[-1]
                if guess in ("x-wav", "wave"):
                    guess = "wav"
                fmt_hint = guess or "wav"
        elif audio.filename and "." in audio.filename:
            fmt_hint = audio.filename.rsplit(".", 1)[-1].lower() or "wav"

        buf = await audio.read()
        label = await _identify_species_from_audio(buf, fmt_hint=fmt_hint)
        wiki_data = await _enrich_with_wikipedia_with_image(label)
        species_id = _get_or_create_species(db, label, wiki_data)
        return {"label": label, "species_id": species_id, "wiki_data": wiki_data}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
