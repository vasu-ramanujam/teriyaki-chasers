# UM EECS 498-002 F25 Teriyaki Chasers

| Video  |  Wiki |  Agile |
|:-----:|:-----:|:--------:|
|[<img src="https://eecs441.eecs.umich.edu/img/admin/video.png">][video]|[<img src="https://eecs441.eecs.umich.edu/img/admin/wiki.png">][wiki]|[<img src="https://eecs441.eecs.umich.edu/img/admin/trello.png">][agile]|
<!-- reusing the icons from eecs441 -->

![Elevator Pitch](https://raw.githubusercontent.com/58456051/133131373-e909da64-93cb-449f-b9f0-3a58dcb1b9db.png) <!-- MUST be placed in publicly accessible github -->
![Team](/assets/team.png)

[video]: https://youtu.be/sample](https://youtu.be/ahn3mXMOfn4
[wiki]: https://github.com/member/team/wiki
[agile]: https://trello.com/b/sample/general <!-- MUST be made public –>

# 🦅 Wildlife Finder 
A comprehensive iOS wildlife tracking and identification app with AI-powered species recognition, interactive maps, AR navigation, and community sighting sharing.

## Quick Start
added justRun.py to the backend, just run this file to run backend at once
### 1) Run the code

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
python justRun.py
```

then go to xcode to run the frontend




## 📱 Overview

Wildlife Finder is a native iOS application that helps users identify, track, and explore wildlife in their area. The app combines AI-powered identification (using OpenAI GPT-4o for images and GPT-4o-audio-preview for sounds), interactive mapping, augmented reality navigation, and community-driven sighting sharing.

## ✨ Key Features

### 🔍 AI-Powered Species Identification
- **Image Identification**: Upload photos to identify wildlife species using GPT-4o vision model
- **Audio Identification**: Record and identify species from bird calls and animal sounds using GPT-4o-audio-preview
- **Multimodal Identification**: Combine both photo and audio for enhanced accuracy
- **Wikipedia Integration**: Automatic enrichment with species descriptions, habitat, diet, and behavior information

### 🗺️ Interactive Mapping
- **Sighting Map**: View wildlife sightings on an interactive map with filtering capabilities
- **High Volume Areas (HVAs)**: Discover hotspots where multiple sightings have been recorded
- **Species Filtering**: Filter sightings by species name with autocomplete suggestions
- **Time-based Filtering**: View sightings from the last 24 hours or custom time ranges

### 🧭 AR Navigation & Routing
- **Augmented Reality Waypoints**: Navigate to wildlife sightings using AR directions
- **Route Generation**: Create optimized routes between multiple waypoints
- **Breadcrumb Trail**: Visual breadcrumbs showing your path in AR

### 📸 Sighting Management
- **Create Sightings**: Post wildlife sightings with photos, audio recordings, captions, and location
- **Media Support**: Upload both images and audio recordings
- **Privacy Controls**: Mark sightings as private or public
- **User Dashboard**: Track your personal sightings and species discoveries

### 🔎 Animal Search
- **Species Search**: Search for animals by name with validation
- **Wikipedia Integration**: Get detailed information about species including images and descriptions
- **Flashcards**: Learn about species you've encountered

### 👤 User Features
- **Personal Dashboard**: View your total sightings, species count, and flashcards
- **User Statistics**: Track your wildlife exploration progress
- **Sighting History**: Browse all your recorded sightings

## 🏗️ Architecture

### Backend (FastAPI)
- **Framework**: FastAPI (Python)
- **Database**: SQLite (development) / PostgreSQL (production via RDS)
- **Storage**: AWS S3 for media files (photos and audio)
- **AI Services**: OpenAI API (GPT-4o, GPT-4o-audio-preview, GPT-4o-mini)
- **APIs**: RESTful API with automatic OpenAPI documentation

### Frontend (iOS)
- **Framework**: SwiftUI
- **Language**: Swift
- **Maps**: MapKit
- **AR**: ARKit
- **Networking**: Alamofire for HTTP requests
- **Architecture**: MVVM pattern with Observable framework


### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/vasu-ramanujam/teriyaki-chasers.git
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


5. **Initialize database**
   ```bash
   python init_db.py
   ```

6. **Run the server**
   ```bash
   # Option 1: Use the all-in-one script
   python justRun.py
   
   # Option 2: Use the standard runner
   python run.py
   ```


### iOS Setup

1. **Open the project**
   ```bash
   cd ios/wildlifeFinder
   open wildlifeFinder.xcodeproj
   ```

2. **Configure API endpoint**
   - Open `wildlifeFinder/Services/APIService.swift`
   - Update the `baseURL` (around line 183) with your backend server address:
     ```swift
     // For simulator (localhost)
     return "http://127.0.0.1:8000/v1"
     
     // For physical device (use your Mac's IP or hostname)
     return "http://YOUR-MAC-IP:8000/v1"
     // Or use hostname: http://YOUR-HOSTNAME.local:8000/v1
     ```

3. **Find your Mac's network address** (for physical device testing)
   ```bash
   # Get hostname
   hostname
   # Output: Your-MacBook-Pro.local
   # Use: http://Your-MacBook-Pro.local:8000/v1
   
   # Or get IP address
   ipconfig getifaddr en0
   # Use: http://192.168.x.x:8000/v1
   ```

4. **Build and run**
   - Select your target device/simulator in Xcode
   - Press `Cmd + R` to build and run


---

**Happy Wildlife Exploring! 🦅🐦🦋**
