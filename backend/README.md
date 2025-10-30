# 🦅 Wildlife Explorer Backend API

A comprehensive FastAPI backend for wildlife sighting tracking and species identification.

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- pip (Python package manager)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd teriyaki-chasers/backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

5. **Initialize database**
   ```bash
   python init_db.py
   ```

6. **Run the server**
   ```bash
   python run.py
   ```

The API will be available at `http://localhost:8000`

## 📚 API Documentation

### Interactive Documentation
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Available Endpoints

#### 🦅 Sightings API
- `GET /v1/sightings` - List sightings with filtering
- `POST /v1/sightings/create` - Create new sighting
- `GET /v1/sightings/{id}` - Get specific sighting details

#### 🐦 Species API
- `GET /v1/species` - Search species
- `GET /v1/species/{id}` - Get species details with Wikipedia enrichment

#### 🧠 AI Identification API
- `POST /v1/identify` - Identify species from image

## 🧪 Testing

### Run All Tests
```bash
python run_all_tests.py
```

### Run Individual Test Suites
```bash
# Sightings API tests
python -m pytest tests/test_sightings_api.py -v

# Species API tests
python -m pytest tests/test_species_api.py -v

# Sighting detail API tests
python -m pytest tests/test_sighting_by_id_api.py -v
```

### Test Coverage
```bash
python -m pytest --cov=app tests/
```

## 🗄️ Database

### Database Schema
- **Species**: Common name, scientific name, habitat, diet, behavior
- **Sightings**: Location, timestamp, media, user info, species reference

### Database Management
```bash
# Reset database (WARNING: Deletes all data)
python reset_db.py

# Initialize with sample data
python init_db.py
```

## 🔧 Configuration

### Environment Variables
- `DATABASE_URL`: Database connection string
- `SECRET_KEY`: JWT secret key
- `DEBUG`: Enable debug mode

### Database Configuration
- **Development**: SQLite (default)
- **Production**: PostgreSQL (configurable)

## 📁 Project Structure

```
backend/
├── app/
│   ├── routers/          # API route handlers
│   ├── services/         # Business logic
│   ├── models.py         # Database models
│   ├── schemas.py        # Pydantic schemas
│   └── main.py          # FastAPI application
├── tests/               # Test suite
├── requirements.txt     # Python dependencies
├── run.py              # Application runner
└── README.md           # This file
```

## 🌐 External Integrations

### Wikipedia Integration
The species API automatically enriches species data with:
- English common names
- Detailed descriptions
- Additional reference sources

### AI Identification
- Image-based species identification
- Confidence scoring
- Multiple species suggestions

## 🚀 Deployment

### Production Setup
1. Set up PostgreSQL database
2. Configure environment variables
3. Install production dependencies
4. Run database migrations
5. Deploy with Gunicorn or similar

### Docker (for testing on a physical device)
```bash
docker compose up --build
# optionally add -d to the end to not show logs
```
*Make sure in APIService.swift that the baseURL is set to ```http://<your_machine_ip>:3000/v1```, where you can get your IP by running: ```curl ifconfig.me```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 🆘 Support

For questions or issues:
1. Check the API documentation at `/docs`
2. Review the test cases for usage examples
3. Create an issue in the repository

---

**Happy Wildlife Exploring! 🦅🐦🦋**
