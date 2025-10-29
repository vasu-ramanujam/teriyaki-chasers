from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Dict, Any
import requests
import base64
import httpx
import os
from app.database import get_db
from app.models import Species
from app.schemas import IdentificationResult, IdentificationCandidate
from app.services.ai_identification import AIIdentificationService
from app.routers.species import _enrich_with_wikipedia, _fetch_wikipedia_summary_by_title

router = APIRouter()

OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


async def identify_with_gpt(file_bytes: bytes, file_type: str) -> str:
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }

    b64_data = base64.b64encode(file_bytes).decode("utf-8")

    if file_type == "photo":
        content = [
            {"type": "text", "text": "Identify the wildlife species shown in this image. Return only its English common name."},
            {"type": "image_url", "image_url": f"data:image/jpeg;base64,{b64_data}"}
        ]
    else:
        content = [
            {"type": "text", "text": "Identify the wildlife species from this audio recording of animal sounds. Return only its English common name."},
            {"type": "input_audio", "input_audio": {"data": b64_data, "format": "wav"}}
        ]

    payload = {
        "model": OPENAI_MODEL,
        "messages": [{"role": "user", "content": content}],
    }

    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(OPENAI_API_URL, headers=headers, json=payload)
        if r.status_code != 200:
            raise HTTPException(status_code=r.status_code, detail=f"OpenAI error: {r.text}")
        result = r.json()
        return result["choices"][0]["message"]["content"].strip()


async def _get_wikipedia_with_image(name: str) -> Dict[str, Any]:
    """get wiki main_image besides summary and other_resources"""
    summary = await _fetch_wikipedia_summary_by_title(name)
    if not summary:
        data = await _enrich_with_wikipedia(name)
        data["main_image"] = None
        return data

    data = {
        "english_name": summary.get("title"),
        "description": summary.get("extract"),
        "other_sources": [],
        "main_image": summary.get("originalimage", {}).get("source")
    }

    content_urls = summary.get("content_urls", {}).get("desktop", {})
    if "page" in content_urls:
        data["other_sources"].append(content_urls["page"])
    if "wikibase_item" in summary:
        data["other_sources"].append(f"https://www.wikidata.org/wiki/{summary['wikibase_item']}")
    return data


@router.post("/photo")
async def identify_photo(photo: UploadFile = File(...), db: Session = Depends(get_db)):
    """Identify animal species from photo"""
    try:
        img_bytes = await photo.read()
        label = await identify_with_gpt(img_bytes, "photo")
        wiki_data = await _get_wikipedia_with_image(label)
        return {
            "label": label,
            "wiki_data": wiki_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/audio")
async def identify_audio(audio: UploadFile = File(...), db: Session = Depends(get_db)):
    """Identify animal species from audio"""
    try:
        audio_bytes = await audio.read()
        label = await identify_with_gpt(audio_bytes, "audio")
        wiki_data = await _get_wikipedia_with_image(label)
        return {
            "label": label,
            "wiki_data": wiki_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))