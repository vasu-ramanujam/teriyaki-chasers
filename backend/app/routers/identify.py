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
OPENAI_AUDIO_MODEL = os.getenv("OPENAI_AUDIO_MODEL", "gpt-4o-audio-preview")
OPENAI_TEXT_MODEL  = os.getenv("OPENAI_TEXT_MODEL", "gpt-4o-mini")

HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "30"))
DEFAULT_UA = "WildlifeExplorer/1.0 (contact: ios-app)"

FAIL_LABEL = "IDENTIFICATION FAILED"

def _require_api_key():
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=500, detail="Missing OPENAI_API_KEY environment variable")


def _get_or_create_species(db: Session, label: str, wiki_data: Optional[Dict[str, Any]]) -> Optional[int]:
    """Ensure we have a Species row for the identified label and return its id."""

    if not label or label == FAIL_LABEL:
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
             "text": "Identify the animal in this image. "
                     "Return the English common name (e.g. 'Red Fox'). "
                     "If you are unsure, provide your best guess. "
                     "If the image definitely does not contain an animal, return 'IDENTIFICATION FAILED'. "
                     "Do not include any other text or punctuation."},
            {"type": "image_url",
             "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}
        ]
    }]
    payload = {"model": OPENAI_IMAGE_MODEL, "messages": messages, "temperature": 0, "modalities": ["text"]}

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"OpenAI image identify error: {r.text}")

    data = r.json()
    print(f"OpenAI Response: {data}")
    label = (data["choices"][0]["message"]["content"] or "").strip()
    print(f"Identified Label: {label}")
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
             "text": "Identify the wildlife species heard in this audio. "
                     "You MUST return exactly one of the following two options:\n"
                     "1) A short English common name like: American Robin\n"
                     "2) The string: IDENTIFICATION FAILED\n"
                     "Do NOT include quotes or any other words before or after. "
                     "If you are unsure but it sounds like wildlife, provide your best guess. "
                     "Only return IDENTIFICATION FAILED if it is clearly not wildlife (e.g. human speech, silence)."},
            {"type": "input_audio",
             "input_audio": {"data": b64, "format": fmt_hint}}
        ]
    }]
    payload = {"model": OPENAI_AUDIO_MODEL, "messages": messages, "temperature": 0, "modalities": ["text"]}

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"OpenAI audio identify error: {r.text}")

    data = r.json()
    print(f"OpenAI Response: {data}")
    label = (data["choices"][0]["message"]["content"] or "").strip()
    print(f"Identified Label: {label}")
    if not label:
        raise HTTPException(status_code=502, detail="Empty label from OpenAI (audio).")
    return label


async def _identify_species_from_image_and_audio(
    image_bytes: bytes,
    audio_bytes: bytes,
    fmt_hint: str = "wav",
) -> str:
    _require_api_key()

    img_b64 = base64.b64encode(image_bytes).decode("utf-8")
    aud_b64 = base64.b64encode(audio_bytes).decode("utf-8")

    url = f"{OPENAI_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": DEFAULT_UA,
    }

    messages = [{
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": (
                    "You are a wildlife identification expert.\n"
                    "You will be given both a photo and an audio recording of the same scene.\n"
                    "Identify the wildlife species using BOTH the image and the audio together.\n"
                    "You MUST return exactly one of the following two options:\n"
                    "1) A short English common name, like: American Robin\n"
                    "2) The string: IDENTIFICATION FAILED\n"
                    "Do NOT include quotes or any other words before or after.\n"
                    "If you cannot identify, or the media does not come from wildlife, "
                    "return IDENTIFICATION FAILED."
                ),
            },
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{img_b64}"},
            },
            {
                "type": "input_audio",
                "input_audio": {"data": aud_b64, "format": fmt_hint},
            },
        ],
    }]

    payload = {
        "model": OPENAI_AUDIO_MODEL,
        "messages": messages,
        "temperature": 0,
        "modalities": ["text"]
    }

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)
    if r.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"OpenAI multimodal identify error: {r.text}",
        )

    data = r.json()
    print(f"OpenAI Response: {data}")
    label = (data["choices"][0]["message"]["content"] or "").strip()
    print(f"Identified Label: {label}")
    if not label:
        raise HTTPException(
            status_code=502,
            detail="Empty label from OpenAI (multimodal).",
        )

    return label



# ------------------ FastAPI routes ------------------



@router.post("/photo")
async def identify_photo(
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    try:
        img = await photo.read()
        print(f"Received Photo Size: {len(img)} bytes, Content-Type: {photo.content_type}")
        label = await _identify_species_from_image(img)

        if label == FAIL_LABEL:
            return {"label": label, "species_id": None, "wiki_data": None}

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
        print(f"Received Audio Size: {len(buf)} bytes, Format Hint: {fmt_hint}")

        if label == FAIL_LABEL:
            return {"label": label, "species_id": None, "wiki_data": None}

        wiki_data = await _enrich_with_wikipedia_with_image(label)
        species_id = _get_or_create_species(db, label, wiki_data)
        return {"label": label, "species_id": species_id, "wiki_data": wiki_data}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/photo-audio")
async def identify_photo_and_audio(
    photo: UploadFile = File(...),
    audio: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    try:
        img_bytes = await photo.read()
        audio_bytes = await audio.read()

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

        final_label = await _identify_species_from_image_and_audio(
            img_bytes, audio_bytes, fmt_hint=fmt_hint
        )
        print(f"Received Audio Size: {len(audio_bytes)} bytes, Format Hint: {fmt_hint}")

        if final_label == FAIL_LABEL:
            return {
                "label": final_label,
                "species_id": None,
                "wiki_data": None,
            }

        wiki_data = await _enrich_with_wikipedia_with_image(final_label)
        species_id = _get_or_create_species(db, final_label, wiki_data)

        return {
            "label": final_label,
            "species_id": species_id,
            "wiki_data": wiki_data,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
