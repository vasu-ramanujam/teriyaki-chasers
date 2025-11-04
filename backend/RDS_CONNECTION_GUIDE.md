# RDS Database Connection Guide

Quick reference for connecting to the AWS RDS PostgreSQL database to work on post sightings.

## 🔗 Connection Information

### RDS Instance Details
- **Endpoint:** `wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com`
- **Port:** `5432`
- **Database Name:** `animal_explorer`
- **Engine:** PostgreSQL 17.6
- **Region:** `us-east-2`

### Database Credentials
Add these to your `.env` file in the `backend/` directory:

```bash
# RDS Configuration
RDS_HOST=wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com
RDS_PORT=5432
RDS_DATABASE=animal_explorer
RDS_USERNAME=wildlife_admin
RDS_PASSWORD=your_password_here
```

**Note:** Get the password from your team lead or `.env` file (never commit passwords to git!)

## 🚀 Quick Setup

### 1. Configure Environment
Copy the RDS configuration above to `backend/.env`

### 2. Test Connection
```bash
cd backend
python3 test_rds_connection.py
```

### 3. Initialize Database (First Time Only)
If tables don't exist yet:
```bash
python3 init_rds_db.py --seed
```

## 📊 Database Schema

### Tables

#### `species`
- `id` (Integer, Primary Key)
- `common_name` (String)
- `scientific_name` (String)
- `habitat`, `diet`, `behavior`, `description` (Text, Optional)
- `created_at` (DateTime)

#### `sightings`
- `id` (String/UUID, Primary Key)
- `user_id` (String, Optional) - **Use this for filtering user sightings**
- `username` (String, Optional) - Display name
- `species_id` (Integer, Foreign Key → species.id)
- `lat` (Float) - Latitude
- `lon` (Float) - Longitude
- `taken_at` (DateTime) - When sighting occurred
- `is_private` (Boolean)
- `media_url` (String, Optional) - S3 URL for images
- `audio_url` (String, Optional) - S3 URL for audio
- `caption` (Text, Optional)
- `created_at` (DateTime)

## 💻 Working with Sightings

### Example: Store a Sighting via Python

```python
from app.database import SessionLocal
from app.models import Sighting, Species
from datetime import datetime
import uuid

db = SessionLocal()

# Get species (assume species_id = 1 exists)
species = db.query(Species).filter(Species.id == 1).first()

# Create sighting
sighting = Sighting(
    id=str(uuid.uuid4()),
    user_id="user_123",
    username="JohnDoe",
    species_id=species.id,
    lat=42.3601,
    lon=-71.0589,
    taken_at=datetime.now(),
    is_private=False,
    media_url="https://bucket.s3.amazonaws.com/image.jpg",
    caption="Saw this near the park"
)

db.add(sighting)
db.commit()
db.refresh(sighting)
print(f"Created sighting: {sighting.id}")
db.close()
```

### Example: Fetch Sightings by User

```python
from app.database import SessionLocal
from app.models import Sighting

db = SessionLocal()

# Filter by user_id (recommended)
user_sightings = db.query(Sighting).filter(
    Sighting.user_id == "user_123"
).all()

# Or filter by username
username_sightings = db.query(Sighting).filter(
    Sighting.username == "JohnDoe"
).all()

for sighting in user_sightings:
    print(f"{sighting.id}: {sighting.caption}")
    
db.close()
```

### Example: Use API Endpoint

The backend API endpoint supports filtering:

**POST** `/v1/sightings/`

Request Body:
```json
{
  "user_id": "user_123",
  "area": "-122.02,-122.01,37.33,37.34",
  "species_id": 1,
  "start_time": "2024-01-01T00:00:00Z",
  "end_time": "2024-12-31T23:59:59Z"
}
```

## 🧪 Testing

### Test Storage
```bash
python3 test_rds_storage.py
```
Creates a test sighting and fetches it back.

### Test Connection
```bash
python3 test_rds_connection.py
```
Verifies RDS connection and shows database status.

### Verify Configuration
```bash
python3 verify_rds_config.py
```
Checks if RDS credentials are properly configured.

## 🛠️ Database Tools

### Connect with GUI Tools

**pgAdmin:**
- Host: `wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com`
- Port: `5432`
- Database: `animal_explorer`
- Username: `wildlife_admin`
- Password: (from .env)

**DBeaver:**
- Same connection details as above
- Driver: PostgreSQL

### Connect via psql Command Line

```bash
psql -h wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com \
     -p 5432 \
     -U wildlife_admin \
     -d animal_explorer
```

## 📝 Important Notes

1. **Media URLs:** All `media_url` and `audio_url` should point to S3 objects
   - Format: `https://bucket-name.s3.region.amazonaws.com/path/to/file`

2. **User Filtering:** Use `user_id` for filtering (more reliable than username)
   - Usernames can be duplicated, but user_id should be unique

3. **Security Group:** Ensure your IP is allowed in RDS security group
   - Contact team lead if connection is denied

4. **Never commit `.env`** to git - it contains sensitive credentials

## 🔧 Troubleshooting

### Connection Timeout
- Check security group allows your IP
- Verify endpoint and credentials
- Ensure RDS instance is running

### Authentication Failed
- Double-check username and password in `.env`
- Verify database name is correct

### Tables Not Found
- Run: `python3 init_rds_db.py --seed`

## 📚 Related Files

- `app/models.py` - Database models
- `app/schemas.py` - API schemas
- `app/routers/sightings.py` - Sightings API endpoints
- `test_rds_storage.py` - Example storage/test script

