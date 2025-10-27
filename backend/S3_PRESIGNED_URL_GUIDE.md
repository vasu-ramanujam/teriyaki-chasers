# S3 Presigned URL Implementation Guide

## Overview

This guide explains how to use S3 presigned URLs for scalable file uploads in the Animal Explorer API.

## Architecture

```
┌─────────┐                ┌─────────┐                ┌─────────┐
│         │  1. Request    │         │                │         │
│  Client │ ───────────>   │ Backend │                │   S3    │
│         │  presigned URL │         │                │         │
└─────────┘                └─────────┘                └─────────┘
     │                           │                          │
     │                           │ 2. Generate presigned    │
     │                           │    URL with metadata     │
     │                           │ ──────────────────────>  │
     │                           │                          │
     │     3. Return URL         │                          │
     │ <────────────────────────│                          │
     │                                                      │
     │ 4. Upload file directly to S3 (PUT request)         │
     │ ─────────────────────────────────────────────────> │
     │                                                      │
     │ 5. S3 stores file                                   │
     │ <───────────────────────────────────────────────── │
     │                                                      │
     │      6. Create sighting with URL                    │
     │ ──────────────────────> Backend                     │
     │                             │                        │
     │      7. Sighting created    │                        │
     │ <────────────────────────   │                        │
     │                                                      │
     │ 8. Access via CDN (optional)                        │
     │ <─────────────────────────────────────────────────> │
```

## Benefits

✅ **Scalability**: Direct client-to-S3 uploads don't consume backend server bandwidth
✅ **Performance**: Faster uploads, especially for large files
✅ **Reliability**: S3 handles durability and availability
✅ **Cost-effective**: Reduced server resources needed
✅ **CDN-ready**: Easy integration with CloudFront for global delivery

## Configuration

### 1. Set up S3 Bucket

```bash
# Create S3 bucket (AWS CLI)
aws s3 mb s3://animal-explorer-media --region us-east-1

# Enable public read access (for public URLs)
aws s3api put-bucket-policy --bucket animal-explorer-media --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::animal-explorer-media/*"
    }
  ]
}'

# Configure CORS for web uploads
aws s3api put-bucket-cors --bucket animal-explorer-media --cors-configuration '{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["PUT", "GET"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}'
```

### 2. Create IAM User with S3 Permissions

```bash
# Create IAM user
aws iam create-user --user-name animal-explorer-uploader

# Attach S3 policy
aws iam put-user-policy --user-name animal-explorer-uploader --policy-name S3UploadPolicy --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:HeadObject"
      ],
      "Resource": "arn:aws:s3:::animal-explorer-media/*"
    }
  ]
}'

# Create access key
aws iam create-access-key --user-name animal-explorer-uploader
```

### 3. Configure Backend (.env)

```env
# Storage Configuration
STORAGE_TYPE=s3

# S3 Settings
S3_BUCKET_NAME=animal-explorer-media
S3_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
S3_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_REGION=us-east-1

# Optional: CDN for faster delivery
CDN_DOMAIN=d123456abcdef.cloudfront.net
```

### 4. (Optional) Set up CloudFront CDN

```bash
# Create CloudFront distribution
aws cloudfront create-distribution --origin-domain-name animal-explorer-media.s3.amazonaws.com \
  --default-root-object index.html
```

## API Usage

### Step 1: Request Presigned URL

**Endpoint**: `POST /api/sightings/upload-url`

**Request**:
```json
{
  "media_type": "image",
  "content_type": "image/jpeg",
  "file_extension": "jpg"
}
```

**Response**:
```json
{
  "upload_url": "https://animal-explorer-media.s3.amazonaws.com/images/2024/01/abc-123.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256...",
  "file_key": "images/2024/01/abc-123.jpg",
  "public_url": "https://d123456abcdef.cloudfront.net/images/2024/01/abc-123.jpg",
  "expires_in": 300
}
```

### Step 2: Upload File to S3

**Method**: `PUT` to `upload_url`

**Headers**:
- `Content-Type`: Must match the content_type from Step 1

**Body**: Raw file bytes

**Example (JavaScript)**:
```javascript
const response = await fetch(uploadData.upload_url, {
  method: 'PUT',
  headers: {
    'Content-Type': 'image/jpeg'
  },
  body: fileBlob
});

if (response.ok) {
  console.log('Upload successful!');
}
```

**Example (Python)**:
```python
import requests

with open('photo.jpg', 'rb') as f:
    response = requests.put(
        upload_data['upload_url'],
        data=f,
        headers={'Content-Type': 'image/jpeg'}
    )
    
if response.status_code == 200:
    print('Upload successful!')
```

**Example (cURL)**:
```bash
curl -X PUT "https://bucket.s3.amazonaws.com/..." \
  -H "Content-Type: image/jpeg" \
  --upload-file photo.jpg
```

### Step 3: Create Sighting with URL

**Endpoint**: `POST /api/sightings`

**Request (multipart/form-data)**:
```
species_id: <uuid>
lat: 37.7749
lon: -122.4194
photo_url: https://d123456abcdef.cloudfront.net/images/2024/01/abc-123.jpg
notes: Uploaded via S3
```

**Response**:
```json
{
  "id": "sighting-uuid",
  "species_id": "species-uuid",
  "lat": 37.7749,
  "lon": -122.4194,
  "taken_at": "2024-01-15T10:30:00Z",
  "media_url": "https://d123456abcdef.cloudfront.net/images/2024/01/abc-123.jpg",
  "notes": "Uploaded via S3"
}
```

## Complete Example

### Python Client

```python
import requests
from pathlib import Path

# Configuration
API_BASE = "http://localhost:8000/api/sightings"
PHOTO_PATH = "bird_photo.jpg"

# Step 1: Request presigned URL
url_response = requests.post(
    f"{API_BASE}/upload-url",
    json={
        "media_type": "image",
        "content_type": "image/jpeg",
        "file_extension": "jpg"
    }
)
url_data = url_response.json()
print(f"Got presigned URL: {url_data['file_key']}")

# Step 2: Upload to S3
with open(PHOTO_PATH, 'rb') as f:
    upload_response = requests.put(
        url_data['upload_url'],
        data=f,
        headers={'Content-Type': 'image/jpeg'}
    )

if upload_response.status_code == 200:
    print("Upload successful!")
    
    # Step 3: Create sighting
    sighting_response = requests.post(
        API_BASE,
        data={
            'species_id': 'your-species-uuid',
            'lat': 37.7749,
            'lon': -122.4194,
            'photo_url': url_data['public_url'],
            'notes': 'Beautiful bird spotted in Golden Gate Park'
        }
    )
    
    sighting = sighting_response.json()
    print(f"Sighting created: {sighting['id']}")
    print(f"View at: {sighting['media_url']}")
else:
    print(f"Upload failed: {upload_response.status_code}")
```

### JavaScript/React Client

```javascript
async function uploadSighting(file, speciesId, lat, lon, notes) {
  try {
    // Step 1: Get presigned URL
    const urlResponse = await fetch('/api/sightings/upload-url', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        media_type: 'image',
        content_type: file.type,
        file_extension: file.name.split('.').pop()
      })
    });
    const urlData = await urlResponse.json();
    
    // Step 2: Upload to S3
    const uploadResponse = await fetch(urlData.upload_url, {
      method: 'PUT',
      headers: { 'Content-Type': file.type },
      body: file
    });
    
    if (!uploadResponse.ok) {
      throw new Error('Upload failed');
    }
    
    // Step 3: Create sighting
    const formData = new FormData();
    formData.append('species_id', speciesId);
    formData.append('lat', lat);
    formData.append('lon', lon);
    formData.append('photo_url', urlData.public_url);
    formData.append('notes', notes);
    
    const sightingResponse = await fetch('/api/sightings', {
      method: 'POST',
      body: formData
    });
    
    const sighting = await sightingResponse.json();
    console.log('Sighting created:', sighting.id);
    return sighting;
    
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}

// Usage in React component
function UploadForm() {
  const handleSubmit = async (e) => {
    e.preventDefault();
    const file = e.target.photo.files[0];
    const speciesId = e.target.species.value;
    const lat = parseFloat(e.target.lat.value);
    const lon = parseFloat(e.target.lon.value);
    const notes = e.target.notes.value;
    
    await uploadSighting(file, speciesId, lat, lon, notes);
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input type="file" name="photo" accept="image/*" required />
      <input type="text" name="species" placeholder="Species ID" required />
      <input type="number" name="lat" placeholder="Latitude" step="any" required />
      <input type="number" name="lon" placeholder="Longitude" step="any" required />
      <textarea name="notes" placeholder="Notes"></textarea>
      <button type="submit">Upload Sighting</button>
    </form>
  );
}
```

## Security Considerations

### URL Expiration
- Presigned URLs expire after 5 minutes (300 seconds)
- Client must upload within this timeframe
- Request a new URL if expired

### Content Type Validation
- Backend validates content type matches allowed types
- S3 upload will fail if Content-Type header doesn't match

### File Size Limits
- Images: 10 MB max
- Audio: 50 MB max
- Enforced by S3 bucket policy (recommended)

### Allowed File Types
- **Images**: JPEG, PNG, HEIC, HEIF, WebP
- **Audio**: MP3, WAV, M4A, OGG

## Troubleshooting

### Error: "Presigned URLs not available"
**Solution**: Set `STORAGE_TYPE=s3` in `.env`

### Error: "AccessDenied" during upload
**Solution**: Check IAM user permissions and S3 bucket policy

### Error: "SignatureDoesNotMatch"
**Solution**: Verify Content-Type header matches the one used to generate presigned URL

### Upload succeeds but file not accessible
**Solution**: Check S3 bucket public access settings and CORS configuration

### Slow uploads
**Solution**: Enable CloudFront CDN for faster delivery globally

## Monitoring

### Check S3 Upload Success (Python)

```python
from app.services.s3_service import s3_service

# Verify file exists after upload
file_key = "images/2024/01/abc-123.jpg"
if s3_service.verify_upload_completed(file_key):
    print("Upload verified!")
else:
    print("File not found in S3")
```

### S3 Metrics (AWS CLI)

```bash
# List recent uploads
aws s3 ls s3://animal-explorer-media/images/2024/01/ --recursive

# Get file metadata
aws s3api head-object --bucket animal-explorer-media --key images/2024/01/abc-123.jpg
```

## Migration from Local to S3

If you're migrating from local storage to S3:

1. **Keep both systems running**: Set `STORAGE_TYPE=local` initially
2. **Upload existing files to S3**: Use AWS CLI or SDK
3. **Update database URLs**: Migrate media_url columns to S3 URLs
4. **Switch to S3**: Set `STORAGE_TYPE=s3` in production
5. **Keep local uploads for development**: Use `STORAGE_TYPE=local` in dev

```python
# Migration script example
import boto3
from pathlib import Path
from app.database import SessionLocal
from app.models import Sighting

s3 = boto3.client('s3')
db = SessionLocal()

for sighting in db.query(Sighting).all():
    if sighting.media_url and sighting.media_url.startswith('/uploads/'):
        # Upload to S3
        local_path = f".{sighting.media_url}"
        s3_key = f"images/migrated/{Path(local_path).name}"
        
        s3.upload_file(local_path, 'animal-explorer-media', s3_key)
        
        # Update database
        sighting.media_url = f"https://cdn.example.com/{s3_key}"
        
db.commit()
```

## Performance Tips

1. **Use CloudFront**: Dramatically reduces latency for global users
2. **Batch uploads**: Request multiple presigned URLs at once using batch endpoint
3. **Progressive uploads**: Show upload progress to users
4. **Retry logic**: Implement exponential backoff for failed uploads
5. **Compress before upload**: Reduce file sizes on client side

## Cost Estimation

- **S3 Storage**: ~$0.023/GB/month
- **S3 PUT requests**: $0.005 per 1,000 requests
- **S3 GET requests**: $0.0004 per 1,000 requests
- **Data transfer out**: First 1 GB free, then $0.09/GB
- **CloudFront**: First 1 TB free tier for 12 months

**Example**: 1,000 photo uploads/month (5MB each, viewed 10,000 times):
- Storage: 5GB × $0.023 = $0.12
- PUT: 1,000 × $0.005 = $0.005
- GET: 10,000 × $0.0004 = $0.004
- **Total**: ~$0.13/month

## Further Reading

- [AWS S3 Presigned URLs Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [boto3 S3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)
