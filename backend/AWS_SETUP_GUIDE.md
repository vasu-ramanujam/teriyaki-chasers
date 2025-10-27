# AWS S3 Integration Guide

This guide documents the AWS S3 setup for storing images and audio files for wildlife sightings.

## 📋 Table of Contents

1. [AWS Account Information](#aws-account-information)
2. [S3 Bucket Configuration](#s3-bucket-configuration)
3. [IAM User Permissions](#iam-user-permissions)
4. [Environment Setup](#environment-setup)
5. [Testing AWS Connection](#testing-aws-connection)
6. [Troubleshooting](#troubleshooting)

---

## 🔐 AWS Account Information

### AWS Console Access

**Sign-in URL:** https://339712839005.signin.aws.amazon.com/console

**IAM User Credentials:**
- **Username:** `teriyaki-chasers-s3-uploader`
- **Password:** `i*)(Qes4|]n_vv|`
- **Access Type:** Programmatic + Console Access

**Sign-in Steps:**
1. Go to the sign-in URL above
2. Select "IAM user"
3. Enter username: `teriyaki-chasers-s3-uploader`
4. Enter password: `i*)(Qes4|]n_vv|`
5. Click "Sign in"

**Programmatic Access (API Keys):**
- **Access Key ID:** `AKIAU6GDWRVO4TV677EC`
- **Secret Access Key:** (stored in `.env` file - DO NOT commit to git)

---

## 📦 S3 Bucket Configuration

### Bucket Details

- **Name:** `teriyaki-chasers-wildlife-media`
- **Region:** `us-east-2` (Ohio)
- **Created:** October 26, 2025
- **Access:** Public read, IAM-controlled write
- **ARN:** `arn:aws:s3:::teriyaki-chasers-wildlife-media`

### Bucket Structure

```
teriyaki-chasers-wildlife-media/
├── sightings/
│   ├── photos/           # Image files (JPG, PNG, etc.)
│   │   └── {UUID}_{filename}
│   └── audio/            # Audio files (MP3, WAV, etc.)
│       └── {UUID}_{filename}
└── test/                  # Test files (temporary)
```

### Supported File Types

**Images:**
- JPG/JPEG
- PNG
- GIF
- WebP

**Audio:**
- MP3
- WAV
- M4A
- OGG
- FLAC

### Bucket Policy (Public Read)

The bucket has the following public read policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media/*"
        }
    ]
}
```

This allows anyone to download/view files via their S3 URLs (required for iOS app to display media).

---

## 🔑 IAM User Permissions

### IAM User Details

**User Name:** `teriyaki-chasers-s3-uploader`  
**Purpose:** Dedicated user for S3 file uploads/downloads  
**Policy Type:** Custom inline policy  

### Permissions Granted

The IAM user has the following permissions:

#### Bucket-Level Permissions
```json
{
    "Effect": "Allow",
    "Action": [
        "s3:ListBucket",
        "s3:HeadBucket"
    ],
    "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media"
}
```

**Actions:**
- `s3:ListBucket` - View bucket contents
- `s3:HeadBucket` - Check if bucket exists and get metadata

#### Object-Level Permissions
```json
{
    "Effect": "Allow",
    "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectAcl"
    ],
    "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media/*"
}
```

**Actions:**
- `s3:PutObject` - Upload files to S3
- `s3:PutObjectAcl` - Set file access control lists
- `s3:DeleteObject` - Delete files from S3
- `s3:GetObject` - Download files from S3
- `s3:GetObjectAcl` - Read file access control information

### Complete IAM Policy JSON

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3BucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:HeadBucket"
            ],
            "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media"
        },
        {
            "Sid": "AllowS3UploadDelete",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:GetObjectAcl"
            ],
            "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media/*"
        }
    ]
}
```

---

## 🚀 Environment Setup

### For New Team Members

After pulling the repository, follow these steps:

#### 1. Install Dependencies

```bash
cd backend
source env/bin/activate  # Activate virtual environment
pip install -r requirements.txt
```

This installs `boto3` and other required packages.

#### 2. Configure Environment Variables

Create a `.env` file in the `backend/` directory:

```bash
cp env.example .env
```

Edit `.env` with your AWS credentials:

```bash
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=AKIAU6GDWRVO4TV677EC
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_REGION=us-east-2
AWS_S3_BUCKET_NAME=teriyaki-chasers-wildlife-media
```

**Security Note:** The `.env` file is in `.gitignore` and should NEVER be committed to git.

#### 3. Update Database Schema

The database has been updated to include `audio_url` field. If you're working with an existing database:

```bash
sqlite3 animal_explorer.db "ALTER TABLE sightings ADD COLUMN audio_url TEXT;"
```

Or recreate the database:

```bash
python init_db.py
```

#### 4. Start the Backend Server

```bash
python run.py
```

The server will start on `http://localhost:8000`

---

## 🧪 Testing AWS Connection

### Automated Test

Run the S3 connection test:

```bash
cd backend
source env/bin/activate
python3 test_s3_connection.py
```

**Expected Output:**
```
✅ ALL TESTS PASSED! S3 Configuration is Working
```

The test will:
1. Check AWS credentials configuration
2. Initialize S3 service
3. Connect to the bucket
4. Upload a test file
5. Verify the upload
6. Delete the test file

### Manual API Test

#### Test 1: Upload Photo Only

```bash
curl -X POST "http://localhost:8000/v1/sightings/create" \
  -F "species_id=1" \
  -F "lat=42.2808" \
  -F "lon=-83.7430" \
  -F "username=TestUser" \
  -F "caption=Testing photo upload" \
  -F "photo=@path/to/your/image.jpg"
```

**Expected Response:**
```json
{
  "id": "...",
  "species_id": 1,
  "media_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/photos/...",
  "audio_url": null,
  ...
}
```

#### Test 2: Upload Audio Only

```bash
curl -X POST "http://localhost:8000/v1/sightings/create" \
  -F "species_id=1" \
  -F "lat=42.2808" \
  -F "lon=-83.7430" \
  -F "username=TestUser" \
  -F "audio=@path/to/your/audio.mp3"
```

**Expected Response:**
```json
{
  "id": "...",
  "species_id": 1,
  "media_url": null,
  "audio_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/audio/...",
  ...
}
```

#### Test 3: Upload Both Photo and Audio

```bash
curl -X POST "http://localhost:8000/v1/sightings/create" \
  -F "species_id=1" \
  -F "lat=42.2808" \
  -F "lon=-83.7430" \
  -F "username=TestUser" \
  -F "photo=@path/to/your/image.jpg" \
  -F "audio=@path/to/your/audio.mp3"
```

**Expected Response:**
```json
{
  "id": "...",
  "species_id": 1,
  "media_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/photos/...",
  "audio_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/audio/...",
  ...
}
```

### Verify File Upload in S3

1. Go to AWS S3 Console: https://console.aws.amazon.com/s3
2. Click on `teriyaki-chasers-wildlife-media` bucket
3. Navigate to `sightings/photos/` or `sightings/audio/`
4. You should see your uploaded files

---

## 🔧 Troubleshooting

### Error: "403 Forbidden" when accessing bucket

**Symptoms:**
```
An error occurred (403) when calling the HeadBucket operation: Forbidden
```

**Causes:**
1. IAM user doesn't have proper permissions
2. Bucket doesn't exist
3. Wrong region specified

**Solutions:**

1. **Check IAM Permissions:**
   - Go to IAM → Users → `teriyaki-chasers-s3-uploader`
   - Verify the policy includes `s3:ListBucket` and `s3:HeadBucket`

2. **Verify Bucket Exists:**
   ```bash
   # Check if bucket exists in the correct region
   aws s3 ls s3://teriyaki-chasers-wildlife-media --region us-east-2
   ```

3. **Check Region in .env:**
   ```bash
   cat .env | grep AWS_REGION
   # Should be: AWS_REGION=us-east-2
   ```

### Error: "AccessControlListNotSupported"

**Symptoms:**
```
The bucket does not allow ACLs
```

**Cause:** Bucket was created with ACL disabled (Object Ownership: ACLs disabled)

**Solution:** Code automatically handles this. The upload code tries ACL first, then falls back to upload without ACL.

### Error: "S3 client not initialized"

**Symptoms:**
```
S3 client not initialized. Please configure AWS credentials in .env file
```

**Cause:** Missing or incorrect AWS credentials in `.env`

**Solutions:**

1. **Check if .env exists:**
   ```bash
   ls -la backend/.env
   ```

2. **Verify credentials:**
   ```bash
   cat backend/.env | grep AWS
   ```
   Should show:
   ```
   AWS_ACCESS_KEY_ID=AKIAU6GDWRVO4TV677EC
   AWS_SECRET_ACCESS_KEY=your_secret_here
   AWS_REGION=us-east-2
   AWS_S3_BUCKET_NAME=teriyaki-chasers-wildlife-media
   ```

3. **Create .env file:**
   ```bash
   cp env.example .env
   # Edit .env with actual credentials
   ```

### Files Not Publicly Accessible

**Symptoms:** Upload works but URL returns 403 when accessed

**Cause:** Bucket policy not set or incorrect

**Solution:**

1. Go to S3 Console → `teriyaki-chasers-wildlife-media` → Permissions
2. Add bucket policy:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [{
           "Sid": "PublicReadGetObject",
           "Effect": "Allow",
           "Principal": "*",
           "Action": "s3:GetObject",
           "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media/*"
       }]
   }
   ```

### Error: "No such file or directory" when starting server

**Cause:** Virtual environment not activated

**Solution:**
```bash
cd backend
source env/bin/activate  # On macOS/Linux
# OR
env\Scripts\activate  # On Windows
```

### Testing: "Server not ready yet"

**Cause:** Backend server not running

**Solution:**
```bash
cd backend
source env/bin/activate
python run.py
```

Wait for: `Application startup complete.`

### Files Uploaded to Wrong Location

**Check:** Verify file structure in S3

**Expected:**
```
sightings/photos/{uuid}_{filename}
sightings/audio/{uuid}_{filename}
```

**If wrong:** Check `s3_service.py` upload_file function folder parameter

---

## 📝 Development Workflow

### Frontend Developers

1. **Setup:**
   ```bash
   # Backend must be running
   cd backend && python run.py
   ```

2. **Upload Media via API:**
   - Use the `/v1/sightings/create` endpoint
   - API accepts both photo and audio
   - Returns S3 URLs that can be used directly in app

3. **Display Media:**
   - Use the `media_url` and `audio_url` from API response
   - Both are public S3 URLs that can be loaded directly
   - Example: `https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/photos/...`

### Backend Developers

1. **Making Changes to Upload Logic:**
   - Edit `backend/app/services/s3_service.py`
   - Edit `backend/app/routers/sightings.py`
   - Test with `python3 test_s3_connection.py`

2. **Debugging Upload Issues:**
   ```bash
   # Enable debug logging
   export AWS_DEBUG_MODE=1
   python3 test_s3_connection.py
   ```

3. **View S3 Files:**
   - Go to AWS Console: https://console.aws.amazon.com/s3
   - Browse `teriyaki-chasers-wildlife-media` bucket
   - Files organized by type (photos/audio)

---

## 🎯 API Usage

### Create Sighting with Media

**Endpoint:** `POST /v1/sightings/create`

**Parameters:**
- `species_id` (int, required) - Species ID from database
- `lat` (float, required) - Latitude
- `lon` (float, required) - Longitude
- `photo` (file, optional) - Image file
- `audio` (file, optional) - Audio file (at least one media type required)
- `username` (string, optional) - User's name
- `caption` (string, optional) - Description
- `is_private` (bool, optional) - Default: false

**Response:**
```json
{
  "id": "uuid-here",
  "species_id": 1,
  "lat": 42.2808,
  "lon": -83.7430,
  "media_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/photos/uuid_filename.jpg",
  "audio_url": "https://teriyaki-chasers-wildlife-media.s3.us-east-2.amazonaws.com/sightings/audio/uuid_filename.mp3",
  "username": "TestUser",
  "caption": "Test caption",
  "taken_at": "2025-10-27T00:00:00",
  "is_private": false,
  "created_at": "2025-10-27T00:00:00"
}
```

---

## 📊 Cost Estimation

**Assumptions:**
- 1,000 sightings per month
- Average photo: 2 MB
- Average audio: 1 MB
- Total: ~3 GB/month

**Estimated Costs:**
- Storage: ~$0.07/month (3 GB × $0.023/GB)
- Upload requests: ~$0.01/month (1,000 PUT requests)
- **Total: ~$0.08/month**

Extremely affordable for production use!

---

## 🔒 Security Notes

1. **Never commit credentials** - `.env` is in `.gitignore`
2. **IAM user has minimal permissions** - Only what's needed for S3 operations
3. **Public read access** - Files are publicly accessible (by design for wildlife sightings)
4. **Files organized by type** - Easy to manage and clean up if needed

---

## 📞 Support

For issues or questions:
1. Check this guide
2. Run `python3 test_s3_connection.py` to verify setup
3. Check AWS Console for bucket and IAM user status
4. Review server logs: `python run.py`

