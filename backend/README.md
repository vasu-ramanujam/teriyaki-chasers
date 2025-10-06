# Animal Explorer Backend

A FastAPI backend for the Animal Explorer iOS app that provides APIs for species identification, wildlife sightings, and routing.

## Quick Start

### Prerequisites
- Python 3.8+
- PostgreSQL database
- Mapbox account (for routing features)
- OpenAI API key (for AI identification)
- iNaturalist API key (optional, for fallback identification)
- BirdWeather API key (for audio identification)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd teriyaki-chasers/backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` with your configuration:
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `MAPBOX_ACCESS_TOKEN`: Your Mapbox API token
   - `OPENAI_API_KEY`: Your OpenAI API key for AI identification
   - `INATURALIST_API_KEY`: Your iNaturalist API key (optional)
   - `BIRDWEATHER_API_KEY`: Your BirdWeather API key for audio identification

5. **Initialize database**
   ```bash
   python init_db.py
   ```

6. **Run the server**
   ```bash
   python run.py
   ```

The API will be available at `http://localhost:8000`

## API Endpoints

- **Species**: `/api/species` - Wildlife species data
- **Sightings**: `/api/sightings` - User wildlife sightings
- **Routing**: `/api/route` - Navigation and routing
- **Identification**: `/api/identify` - AI-powered species identification
  - `POST /api/identify/photo` - Identify species from photos
  - `POST /api/identify/audio` - Identify species from audio recordings

## API Documentation

Visit `http://localhost:8000/docs` for interactive API documentation.

## AI Features

The backend includes AI-powered wildlife identification:

- **Photo Identification**: Uses OpenAI GPT-4 Vision to identify species from photos
- **Audio Identification**: Uses OpenAI Whisper + GPT-4 to identify species from audio recordings
- **Fallback Support**: Falls back to mock data if AI services are unavailable (for development)

### Getting API Keys

1. **OpenAI API Key**: 
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create an account and generate an API key
   - Add billing information (pay-per-use)

2. **iNaturalist API Key** (Optional):
   - Visit [iNaturalist API](https://www.inaturalist.org/pages/api+reference)
   - Create an account and request API access

3. **BirdWeather API Key**:
   - Visit [BirdWeather API](https://app.birdweather.com/api/v1)
   - Create an account and generate an API key
   - Free tier available with rate limits

## Health Check

- Root: `GET /`
- Health: `GET /health`
