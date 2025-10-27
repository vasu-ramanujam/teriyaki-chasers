# Image and Audio Storage Service

## Overview

The storage service provides a flexible solution for handling media uploads (images and audio) in the Animal Explorer API. It supports both local file storage and scalable S3-compatible cloud storage with presigned URLs.

## Features

### ✅ Image Storage
- **Supported formats**: JPEG, PNG, HEIC, HEIF, WebP
- **Max size**: 10 MB
- **Automatic thumbnail generation** (300x300px)
- **Format conversion**: Thumbnails saved as JPEG for efficiency
- **RGBA to RGB conversion** for compatibility

### ✅ Audio Storage
- **Supported formats**: MP3, WAV, M4A, OGG
- **Max size**: 50 MB
- **Direct storage** without processing

### ✅ Validation
- File type validation
- File size limits
- Content type checking
- Security best practices

### ✅ Storage Options
- **Local storage**: Files uploaded through backend server
- **S3 storage**: Scalable cloud storage with presigned URLs for direct client uploads

## Storage Architecture

### Local Storage Mode
Client → Backend (file upload) → Local Disk → Backend returns URL

**Pros**: Simple, no external dependencies
**Cons**: Server bandwidth consumed, not scalable

### S3 Presigned URL Mode (Recommended for Production)
1. Client → Backend: Request presigned upload URL
2. Backend → Client: Return presigned URL + file key
3. Client → S3: Upload file directly using presigned URL
4. Client → Backend: Create sighting with file key/URL

**Pros**: Scalable, reduces server load, faster uploads
**Cons**: Requires S3 setup

## Configuration

### Environment Variables (.env)

```env
# Storage settings
STORAGE_TYPE=local                  # "local" or "s3"
UPLOAD_DIRECTORY=uploads            # Local storage directory (if local)
API_BASE_URL=http://127.0.0.1:8000 # Base URL for file access (if local)

# S3 settings (if STORAGE_TYPE=s3)
S3_BUCKET_NAME=your-bucket-name
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_REGION=us-east-1
S3_ENDPOINT_URL=https://s3.amazonaws.com  # Optional for S3-compatible services

# CDN settings (optional, for S3 mode)
CDN_DOMAIN=d123456.cloudfront.net  # CloudFront or CDN domain for faster delivery
```

## Database Schema

### Sighting Model Fields

```python
media_url: str          # URL to full-size image
media_thumb_url: str    # URL to thumbnail (300x300)
audio_url: str          # URL to audio recording
notes: str              # Text notes about the sighting
```

## API Endpoints

### 🆕 POST /api/sightings/upload-url

**Generate presigned URL for direct S3 upload (S3 mode only)**

This endpoint enables scalable file uploads by allowing clients to upload directly to S3, bypassing the backend server.

**Request (JSON):**

```json
{
  "media_type": "image",           // "image" or "audio"
  "content_type": "image/jpeg",    // MIME type
  "file_extension": "jpg"          // File extension
}
```

**Response:**

```json
{
  "upload_url": "https://bucket.s3.amazonaws.com/images/2024/01/uuid.jpg?X-Amz-...",
  "file_key": "images/2024/01/uuid.jpg",
  "public_url": "https://d123456.cloudfront.net/images/2024/01/uuid.jpg",
  "expires_in": 300  // Seconds until upload_url expires
}
```

**Upload Flow:**

```bash
# 1. Request presigned URL
curl -X POST http://localhost:8000/api/sightings/upload-url \
  -H "Content-Type: application/json" \
  -d '{
    "media_type": "image",
    "content_type": "image/jpeg",
    "file_extension": "jpg"
  }'

# 2. Upload file to S3 using presigned URL (PUT request)
curl -X PUT "<upload_url>" \
  -H "Content-Type: image/jpeg" \
  --upload-file photo.jpg

# 3. Create sighting with public URL
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=<uuid>" \
  -F "lat=37.7749" \
  -F "lon=-122.4194" \
  -F "photo_url=<public_url>"
```

**Error Responses:**

- `501`: Presigned URLs not available (storage_type is not "s3")
- `400`: Invalid media_type or content_type
- `500`: Failed to generate URL

### POST /api/sightings

Create a new sighting with media uploads.

**Two modes supported:**

#### Mode 1: Direct Upload (Local Storage)

**Request (multipart/form-data):**

```
species_id: string (required)
lat: float (required)
lon: float (required)
is_private: boolean (default: false)
username: string (optional) - Display name for the user
photo: file (optional) - Image file
audio: file (optional) - Audio file
notes: string (optional) - Text notes
```

#### Mode 2: S3 URLs (After Presigned Upload)

**Request (multipart/form-data):**

```
species_id: string (required)
lat: float (required)
lon: float (required)
is_private: boolean (default: false)
username: string (optional) - Display name for the user
photo_url: string (optional) - S3 URL for uploaded photo
photo_thumb_url: string (optional) - S3 URL for thumbnail
audio_url: string (optional) - S3 URL for uploaded audio
notes: string (optional) - Text notes
```

**Note**: At least one media source (file or URL) is required.

**Response:**

```json
{
  "id": "uuid",
  "species_id": "uuid",
  "lat": 37.7749,
  "lon": -122.4194,
  "taken_at": "2024-01-15T10:30:00",
  "is_private": false,
  "media_url": "https://cdn.example.com/images/2024/01/uuid.jpg",
  "media_thumb_url": "https://cdn.example.com/images/2024/01/thumb_uuid.jpg",
  "audio_url": "https://cdn.example.com/audios/2024/01/uuid.mp3",
  "notes": "Beautiful bird spotted in the park",
  "user_id": null,
  "created_at": "2024-01-15T10:30:00"
}
```

## File Structure

### Local Storage

```
uploads/
├── images/
│   ├── uuid1.jpg           # Original images
│   ├── uuid2.png
│   └── thumbnails/
│       ├── thumb_uuid1.jpg # Thumbnails (always JPEG)
│       └── thumb_uuid2.jpg
└── audio/
    ├── uuid1.mp3           # Audio files
    └── uuid2.wav
```

### S3 Storage

Files are organized by type and date for efficient retrieval:

```
s3://your-bucket/
├── images/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── abc123-def456.jpg
│   │   │   └── ghi789-jkl012.png
│   │   └── 02/
│   │       └── mno345-pqr678.jpg
│   └── thumbnails/
│       └── 2024/
│           └── 01/
│               └── thumb_abc123-def456.jpg
└── audios/
    └── 2024/
        └── 01/
            ├── xyz123-abc456.mp3
            └── def789-ghi012.wav
```

**File naming convention**: `{uuid}.{extension}`
- UUID ensures uniqueness
- Extension preserved from original file
- Organized by year/month for scalability

## Usage Examples

### S3 Presigned URL Flow (Recommended)

```python
import requests

# Step 1: Request presigned URL for image upload
response = requests.post(
    'http://localhost:8000/api/sightings/upload-url',
    json={
        'media_type': 'image',
        'content_type': 'image/jpeg',
        'file_extension': 'jpg'
    }
)
upload_data = response.json()
# {
#   "upload_url": "https://bucket.s3.amazonaws.com/...",
#   "file_key": "images/2024/01/uuid.jpg",
#   "public_url": "https://cdn.example.com/images/2024/01/uuid.jpg",
#   "expires_in": 300
# }

# Step 2: Upload file directly to S3
with open('bird.jpg', 'rb') as f:
    upload_response = requests.put(
        upload_data['upload_url'],
        data=f,
        headers={'Content-Type': 'image/jpeg'}
    )
    
if upload_response.status_code == 200:
    # Step 3: Create sighting with S3 URL
    sighting_response = requests.post(
        'http://localhost:8000/api/sightings',
        data={
            'species_id': 'species-uuid',
            'lat': 37.7749,
            'lon': -122.4194,
            'photo_url': upload_data['public_url'],
            'notes': 'Uploaded via S3'
        }
    )
    print(sighting_response.json())
```

### Local Storage Flow (Direct Upload)

```python
import requests

# Create sighting with photo and audio
with open('bird.jpg', 'rb') as photo, open('bird_song.mp3', 'rb') as audio:
    response = requests.post(
        'http://localhost:8000/api/sightings',
        files={
            'photo': ('bird.jpg', photo, 'image/jpeg'),
            'audio': ('bird_song.mp3', audio, 'audio/mpeg')
        },
        data={
            'species_id': 'species-uuid',
            'lat': 37.7749,
            'lon': -122.4194,
            'notes': 'Heard singing in oak tree'
        }
    )
    
print(response.json())
```

### cURL

```bash
# S3 Presigned URL Flow
# 1. Get presigned URL
curl -X POST http://localhost:8000/api/sightings/upload-url \
  -H "Content-Type: application/json" \
  -d '{"media_type":"image","content_type":"image/jpeg","file_extension":"jpg"}'

# 2. Upload to S3 (replace <upload_url> with URL from step 1)
curl -X PUT "<upload_url>" \
  -H "Content-Type: image/jpeg" \
  --upload-file bird.jpg

# 3. Create sighting with URL
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=species-uuid" \
  -F "lat=37.7749" \
  -F "lon=-122.4194" \
  -F "photo_url=<public_url>" \
  -F "notes=Uploaded via S3"

# Local Storage Flow
# Upload with photo only
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=species-uuid" \
  -F "lat=37.7749" \
  -F "lon=-122.4194" \
  -F "photo=@bird.jpg" \
  -F "notes=Beautiful bird"

# Upload with audio only
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=species-uuid" \
  -F "lat=37.7749" \
  -F "lon=-122.4194" \
  -F "audio=@bird_song.mp3"

# Upload with both
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=species-uuid" \
  -F "lat=37.7749" \
  -F "lon=-122.4194" \
  -F "photo=@bird.jpg" \
  -F "audio=@bird_song.mp3" \
  -F "notes=Complete sighting"
```

## Migration

Run the migration script to add new columns to existing database:

```bash
cd backend
python migrate_add_media_columns.py
```

This will add:
- `media_thumb_url` column
- `audio_url` column

The `notes` column should already exist from the previous migration.

## Error Handling

### Common Errors

**400 Bad Request - Invalid file type:**
```json
{
  "detail": "Invalid file type. Allowed: image/jpeg, image/png, image/heic, image/heif, image/webp"
}
```

**400 Bad Request - File too large:**
```json
{
  "detail": "File too large. Maximum size: 10.0 MB"
}
```

**400 Bad Request - No media provided:**
```json
{
  "detail": "At least one media file (photo or audio) is required"
}
```

**404 Not Found - Invalid species:**
```json
{
  "detail": "Species not found"
}
```

## Security Considerations

### Implemented
- ✅ File type validation (whitelist)
- ✅ File size limits
- ✅ Unique filenames (UUID-based)
- ✅ Content type verification

### Recommended for Production
- [ ] Add user authentication
- [ ] Implement rate limiting
- [ ] Add virus scanning for uploads
- [ ] Implement file access permissions
- [ ] Use signed URLs for S3
- [ ] Add Content Security Policy headers
- [ ] Implement upload quotas per user

## Performance

### Thumbnail Generation
- Uses PIL with LANCZOS resampling for quality
- JPEG compression at 85% quality
- Optimized output files
- Async processing doesn't block response

### File Serving
- Local files served via StaticFiles middleware
- Efficient streaming for large files
- Consider CDN for production

## Future Enhancements

### Planned Features
- [ ] S3 storage implementation
- [ ] Image resizing to multiple sizes
- [ ] Video support
- [ ] WebP conversion for modern browsers
- [ ] Automatic EXIF data extraction
- [ ] Geolocation from EXIF
- [ ] Duplicate detection
- [ ] Batch upload support
- [ ] Progress indicators for large files
- [ ] Background processing with Celery

### Storage Providers
- [ ] AWS S3
- [ ] Google Cloud Storage
- [ ] Azure Blob Storage
- [ ] DigitalOcean Spaces
- [ ] Cloudflare R2

## Testing

The storage service includes validation and error handling. Test with:

```bash
# Test with valid image
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=test-species" \
  -F "lat=0" \
  -F "lon=0" \
  -F "photo=@test.jpg"

# Test with invalid file type
curl -X POST http://localhost:8000/api/sightings \
  -F "species_id=test-species" \
  -F "lat=0" \
  -F "lon=0" \
  -F "photo=@test.txt"
```

## Troubleshooting

### Issue: "Module 'PIL' not found"
**Solution**: Install Pillow
```bash
pip install pillow>=10.2.0
```

### Issue: "Permission denied" when creating uploads directory
**Solution**: Check directory permissions
```bash
chmod 755 uploads
```

### Issue: Thumbnails not generated
**Solution**: Check logs for PIL errors. Ensure Pillow supports the image format.

### Issue: Files not accessible via URL
**Solution**: Verify StaticFiles is mounted correctly in main.py and STORAGE_TYPE=local

## Development

### Adding New File Types

Edit `app/services/storage.py`:

```python
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": [".jpg", ".jpeg"],
    "image/gif": [".gif"],  # Add this
    # ...
}
```

### Changing Size Limits

Edit `app/services/storage.py`:

```python
MAX_IMAGE_SIZE = 20 * 1024 * 1024  # 20 MB
MAX_AUDIO_SIZE = 100 * 1024 * 1024  # 100 MB
```

### Customizing Thumbnails

```python
THUMBNAIL_SIZE = (500, 500)  # Larger thumbnails
# Or preserve aspect ratio:
image.thumbnail(THUMBNAIL_SIZE, Image.LANCZOS)
```

## Support

For issues or questions:
1. Check the logs in the terminal where the API is running
2. Verify your .env configuration
3. Ensure all migrations have been run
4. Check file permissions on upload directory

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-09
