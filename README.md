# Animal Explorer

An iOS app for discovering and documenting wildlife sightings with map visualization, species identification, and AR routing features.

## Features

### Skeleton (Core Features)
- **View/Select Sightings**: Interactive map showing recent animal sightings
- **GPS Coordinates**: Automatic location collection and display
- **Direct Routes**: Get directions to specific sightings
- **Photo Identification**: AI-powered species identification from photos
- **Animal Details**: Comprehensive species information cards
- **Post Sightings**: Share your discoveries with privacy controls

### MVP Features
- **Species Filtering**: Filter map by specific animal species
- **Route Augmentation**: Add nearby sightings to your route
- **Historical Data**: Use past sightings to suggest popular areas
- **AR Mode**: Augmented reality route visualization
- **Species Search**: Quick autocomplete search for animals
- **Notifications**: Get alerts for nearby sightings

## Architecture

### Backend (Python/FastAPI)
- **Framework**: FastAPI with async support
- **Database**: PostgreSQL with PostGIS for geospatial queries
- **Storage**: Local file storage (S3/GCS ready)
- **APIs**: RESTful endpoints for sightings, species, routing, and identification

### iOS App (SwiftUI)
- **Framework**: SwiftUI with MVVM architecture
- **Maps**: MapKit for interactive map visualization
- **Camera**: AVFoundation for photo capture
- **AR**: ARKit for augmented reality routing
- **Location**: CoreLocation for GPS services

## Quick Start

### Backend Setup

1. **Install Dependencies**
   ```bash
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Database Setup**
   ```bash
   # Install PostgreSQL with PostGIS
   brew install postgresql postgis
   brew services start postgresql
   
   # Create database
   createdb animal_explorer
   psql -d animal_explorer -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   ```

3. **Environment Configuration**
   ```bash
   cp env.example .env
   # Edit .env with your database URL and API keys
   ```

4. **Run Backend**
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

### iOS Setup

1. **Open Project**
   ```bash
   open ios/AnimalExplorer/AnimalExplorer.xcodeproj
   ```

2. **Configure API URL**
   - Update `APIClient.swift` with your backend URL
   - Default: `http://127.0.0.1:8000/api`

3. **Build and Run**
   - Select iOS Simulator or device
   - Build and run (⌘+R)

## API Endpoints

### Species
- `GET /api/species?q={query}&limit={limit}` - Search species
- `GET /api/species/{id}` - Get species details

### Sightings
- `GET /api/sightings?bbox={bbox}&since={date}&species_id={id}` - Get sightings
- `POST /api/sightings` - Create new sighting

### Identification
- `POST /api/identify/photo` - Identify species from photo
- `POST /api/identify/audio` - Identify species from audio

### Routing
- `POST /api/route` - Create route between points
- `GET /api/route/sightings-near?route_id={id}&radius_m={radius}` - Find nearby sightings
- `POST /api/route/{id}/augment` - Add waypoints to route

## Database Schema

### Core Tables
- `species` - Animal species information
- `sightings` - User sightings with geospatial data
- `routes` - Route information and polylines
- `route_waypoints` - Waypoints along routes

### Key Indexes
- `sightings.geom` - GIST index for spatial queries
- `sightings.species_id` - B-tree index for species filtering
- `sightings.created_at` - B-tree index for time-based queries

## Development

### Backend Development
```bash
# Install development dependencies
pip install alembic httpx black isort

# Run database migrations
alembic upgrade head

# Run tests
pytest

# Format code
black app/
isort app/
```

### iOS Development
- Use Xcode 15+ with iOS 17+ deployment target
- Enable location permissions in Info.plist
- Configure camera permissions for photo capture

## Deployment

### Backend
- Use Docker for containerization
- Deploy to cloud platforms (Railway, Render, Fly.io)
- Configure environment variables
- Set up PostgreSQL with PostGIS

### iOS
- Configure App Store Connect
- Set up provisioning profiles
- Configure push notifications
- Test on physical devices

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details