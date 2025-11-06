from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional, Dict, Any
import httpx
from app.database import get_db
from app.models import Species as SpeciesModel
from app.schemas import Species, SpeciesSearch, SpeciesDetail, SpeciesDetails

router = APIRouter()

WIKI_SUMMARY_URL = "https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
WIKI_SEARCH_URL = "https://en.wikipedia.org/w/api.php"

DEFAULT_UA = "AnimalExplorer/1.0 (contact: ios-app)"
HTTP_TIMEOUT = 8.0 # seconds

async def _fetch_wikipedia_summary_by_title(title: str) -> Optional[Dict[str, Any]]:
    """Use REST summary API to get page summary, return None when not exist"""
    url = WIKI_SUMMARY_URL.format(title=title.replace(" ", "_"))
    headers = {"User-Agent": DEFAULT_UA, "Accept": "application/json"}
    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.get(url)
        if r.status_code == 200:
            return r.json()
        return None


async def _search_wikipedia_title(q: str) -> Optional[str]:
    """Use MediaWiki search API to find the latest relevant title (return title string ot None)"""
    params = {
        "action": "query",
        "list": "search",
        "srsearch": q,
        "srlimit": 1,
        "format": "json",
        "utf8": 1,
    }
    headers = {"User-Agent": DEFAULT_UA}
    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT, headers=headers) as client:
        r = await client.get(WIKI_SEARCH_URL, params=params)
        if r.status_code != 200:
            return None
        data = r.json()
        search = data.get("query", {}).get("search", [])
        if not search:
            return None
        # return the title of the first search result
        return search[0].get("title")


def _extract_fields_from_summary(summary: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract from  summary JSON:
        - english_name: summary['title']
        - description:  summary['extract']
        - other_sources: wiki page URL + Wikidata (if exist)
    """
    title = summary.get("title")  # common English name
    extract = summary.get("extract")  # summary
    other_sources: List[str] = []

    # Wikipedia page
    content_urls = summary.get("content_urls", {})
    desktop = content_urls.get("desktop", {})
    page_url = desktop.get("page")
    if page_url:
        other_sources.append(page_url)

    # Wikidata (if REST summary exposes wikibase_item)
    wikibase = summary.get("wikibase_item")
    if wikibase:
        other_sources.append(f"https://www.wikidata.org/wiki/{wikibase}")

    return {
        "english_name": title,
        "description": extract,
        "other_sources": other_sources,
    }


async def _enrich_with_wikipedia_with_image(name: str) -> Dict[str, Any]:
    summary = await _fetch_wikipedia_summary_by_title(name)
    if not summary:
        title = await _search_wikipedia_title(name)
        if title:
            summary = await _fetch_wikipedia_summary_by_title(title)

    if not summary:
        return {
            "english_name": None,
            "description": None,
            "other_sources": [],
            "main_image": None,
        }

    data = _extract_fields_from_summary(summary)

    main_image = None
    orig = summary.get("originalimage")
    if isinstance(orig, dict):
        main_image = orig.get("source")

    data["main_image"] = main_image
    return data

async def _enrich_with_wikipedia(scientific_name: str) -> Dict[str, Any]:
    """
    First, try to search for summary with scientific_name.
    If fail, search for title then get summary.
    Return None when unable to get items.
    """
    # 1) use scientific_name as title
    summary = await _fetch_wikipedia_summary_by_title(scientific_name)
    if not summary:
        # 2) use search api to find a more possible title
        title = await _search_wikipedia_title(scientific_name)
        if title:
            summary = await _fetch_wikipedia_summary_by_title(title)

    if summary:
        return _extract_fields_from_summary(summary)

    # return None when external failures
    return {"english_name": None, "description": None, "other_sources": []}


@router.get("/", response_model=SpeciesSearch)
async def search_species(
    q: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Search species by common or scientific name"""
    query = db.query(SpeciesModel).filter(
        func.lower(SpeciesModel.common_name).contains(q.lower()) |
        func.lower(SpeciesModel.scientific_name).contains(q.lower())
    ).limit(limit)
    
    species_list = query.all()
    return SpeciesSearch(items=species_list)

@router.get("/id/{species_id}", response_model=Species)
async def get_species_by_id(
    species_id: int,
    db: Session = Depends(get_db)
):
    species = db.query(SpeciesModel).filter(SpeciesModel.id == species_id).first()
    if not species:
        raise HTTPException(status_code=404, detail="Species not found")
    return species

@router.get("/{species_id}", response_model=SpeciesDetails)
async def get_species(
    species_id: int,
    db: Session = Depends(get_db)
):
    """Get species details by ID with Wikipedia enrichment"""
    species = db.query(SpeciesModel).filter(SpeciesModel.id == species_id).first()
    if not species:
        raise HTTPException(status_code=404, detail="Species not found")
    
    scientific_name = getattr(species, "scientific_name", None)
    
    # Enrich with Wikipedia data
    wiki = await _enrich_with_wikipedia(scientific_name)
    
    # Return the species details with image
    return SpeciesDetails(
        species=scientific_name,
        english_name=wiki["english_name"],
        description=wiki["description"],
        other_sources=wiki["other_sources"],
    )
