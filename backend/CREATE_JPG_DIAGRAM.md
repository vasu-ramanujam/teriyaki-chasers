# How to Create JPG Diagram for AI Identification Workflow

## Option 1: Using Python Script (Recommended)

### Step 1: Install Dependencies
```bash
cd backend
pip install -r diagram_requirements.txt
```

### Step 2: Run the Script
```bash
python3 generate_diagram.py
```

### Step 3: Convert to JPG
```bash
# Using ImageMagick
convert ai_identification_workflow.png ai_identification_workflow.jpg

# Or using Python
python3 -c "
from PIL import Image
img = Image.open('ai_identification_workflow.png')
img.save('ai_identification_workflow.jpg', 'JPEG', quality=95)
"
```

## Option 2: Using Mermaid Live Editor

### Step 1: Go to Mermaid Live Editor
Visit: https://mermaid.live/

### Step 2: Copy Mermaid Code
Copy this code into the editor:

```mermaid
graph TD
    A[📱 iOS App<br/>User takes photo] --> B[🌐 Network Request<br/>POST /api/identify/photo]
    B --> C[🖥️ FastAPI Server<br/>localhost:8000]
    C --> D[🔧 Image Processing<br/>Validate & Compress]
    D --> E[🧠 AI Service<br/>identify_photo()]
    E --> F[🤖 OpenAI GPT-4 Vision<br/>Primary API]
    
    F --> G{Success?}
    G -->|Yes| H{Confidence ≥ 0.8?}
    H -->|Yes| I[✅ Return Result<br/>High Confidence]
    H -->|No| J[🌿 iNaturalist API<br/>Fallback]
    G -->|No| J
    
    J --> K{Success?}
    K -->|Yes| L[🔄 Compare Results<br/>Choose Best]
    K -->|No| M[🎭 Mock Data<br/>Development Fallback]
    
    L --> N[📋 JSON Response<br/>Species + Confidence]
    I --> N
    M --> N
    
    N --> O[📤 HTTP Response<br/>200 OK]
    O --> P[📱 iOS Display<br/>Show Results]
```

### Step 3: Download as PNG
1. Click "Download" button
2. Select "PNG" format
3. Save the file

### Step 4: Convert to JPG
Use any image editor or online converter to convert PNG to JPG.

## Option 3: Using Draw.io (Lucidchart)

### Step 1: Go to Draw.io
Visit: https://app.diagrams.net/

### Step 2: Create New Diagram
1. Click "Create New Diagram"
2. Choose "Blank Diagram"
3. Name it "AI Identification Workflow"

### Step 3: Add Components
Create boxes for each component:
- iOS App (Client)
- Network Request
- FastAPI Server
- Image Processing
- AI Service
- OpenAI GPT-4 Vision
- iNaturalist API
- Mock Data
- JSON Response
- Display Results

### Step 4: Add Arrows
Connect components with arrows showing the flow.

### Step 5: Export as JPG
1. File → Export as → JPG
2. Choose high quality
3. Save the file

## Option 4: Using VS Code with Mermaid Extension

### Step 1: Install Extension
1. Open VS Code
2. Go to Extensions
3. Search for "Mermaid Preview"
4. Install the extension

### Step 2: Create Mermaid File
1. Create `workflow.mmd` file
2. Add the mermaid code from Option 2
3. Right-click → "Export as PNG"
4. Convert PNG to JPG

## Option 5: Using Command Line Tools

### Install Mermaid CLI
```bash
npm install -g @mermaid-js/mermaid-cli
```

### Create Diagram
```bash
# Create mermaid file
cat > workflow.mmd << 'EOF'
graph TD
    A[📱 iOS App] --> B[🌐 Network]
    B --> C[🖥️ Server]
    C --> D[🔧 Processing]
    D --> E[🧠 AI Service]
    E --> F[🤖 OpenAI]
    F --> G[📋 Response]
    G --> H[📱 Display]
EOF

# Convert to PNG
mmdc -i workflow.mmd -o workflow.png

# Convert to JPG
convert workflow.png workflow.jpg
```

## Option 6: Using Online Tools

### Canva
1. Go to https://canva.com
2. Create new design
3. Use flowchart templates
4. Add your components
5. Export as JPG

### Figma
1. Go to https://figma.com
2. Create new file
3. Use flowchart components
4. Export as JPG

## Quick Start (Easiest Method)

### Run the Script
```bash
cd backend
chmod +x create_diagram.sh
./create_diagram.sh
```

This will:
1. Install required packages
2. Generate the diagram
3. Create PNG and SVG files
4. Show instructions for JPG conversion

## Output Files

After running any method, you'll get:
- `ai_identification_workflow.png` - High quality PNG
- `ai_identification_workflow.svg` - Vector format
- `ai_identification_workflow.jpg` - JPG format (after conversion)

## Troubleshooting

### Python Issues
```bash
# Install Python packages
pip3 install matplotlib numpy pillow

# Run script
python3 generate_diagram.py
```

### ImageMagick Issues
```bash
# Install ImageMagick
brew install imagemagick  # macOS
sudo apt-get install imagemagick  # Ubuntu

# Convert to JPG
convert ai_identification_workflow.png ai_identification_workflow.jpg
```

### Mermaid Issues
```bash
# Install Node.js first
# Then install mermaid-cli
npm install -g @mermaid-js/mermaid-cli
```

## Final Result

You'll get a professional-looking JPG diagram showing:
- Complete workflow from iOS app to AI identification
- All components (OpenAI, iNaturalist, Mock Data)
- Decision points and fallback logic
- Color-coded components
- Professional layout

The diagram will be perfect for presentations, documentation, or sharing with your team!
