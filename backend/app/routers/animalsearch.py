import os
import difflib
from typing import Tuple

import httpx
from fastapi import APIRouter, HTTPException
from app.schemas import AnimalSearchRequest, AnimalSearchResponse
from app.config import settings

router = APIRouter()


OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

OPENAI_TEXT_MODEL = os.getenv("OPENAI_TEXT_MODEL", "gpt-4o-mini")

HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "30"))
DEFAULT_UA = "WildlifeExplorer/1.0 (contact: ios-app)"


def _require_api_key():
    if not OPENAI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Missing OPENAI_API_KEY environment variable",
        )


async def _validate_animal_name_with_llm(name: str) -> Tuple[bool, str]:
    _require_api_key()

    url = f"{OPENAI_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": DEFAULT_UA,
    }

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": (
                        "You are validating an English animal name.\n\n"
                        f"Name: {name}\n\n"
                        "Answer with EXACTLY one word:\n"
                        "- 'YES' if this is the English common name of a real animal species "
                        "(including birds, mammals, reptiles, amphibians, fish, insects, etc.).\n"
                        "- 'NO' if it is not an animal, is a person, place, object, fictional character, "
                        "or otherwise not a real animal species name.\n\n"
                        "Only respond with 'YES' or 'NO'. No other text."
                    ),
                }
            ],
        }
    ]

    payload = {
        "model": OPENAI_TEXT_MODEL,
        "messages": messages,
        "temperature": 0,
    }

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.post(url, json=payload)

    if r.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"OpenAI animal-name validation error: {r.text}",
        )

    data = r.json()
    raw = (data["choices"][0]["message"]["content"] or "").strip()
    upper = raw.upper()

    is_valid = upper == "YES"
    return is_valid

def _return_suggestions(search: str, limit: int = 5):
    return difflib.get_close_matches(search, settings.animal_names, limit, 0.25)


@router.post("/validate-name", response_model=AnimalSearchResponse)
async def validate_animal_name(body: AnimalSearchRequest) -> AnimalSearchResponse:
    try:
        is_valid = await _validate_animal_name_with_llm(body.name)
        return AnimalSearchResponse(
            name=body.name,
            is_valid=is_valid,
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Animal name validation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{query}")
def get_suggestions(query: str):
    return _return_suggestions(query)