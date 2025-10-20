#!/bin/bash

# Animal Explorer Setup Script
echo "🐾 Setting up Animal Explorer..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This setup script is designed for macOS"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install PostgreSQL and PostGIS
echo "🗄️ Installing PostgreSQL and PostGIS..."
brew install postgresql postgis

# Start PostgreSQL service
echo "🚀 Starting PostgreSQL..."
brew services start postgresql

# Create database
echo "📊 Creating database..."
createdb animal_explorer 2>/dev/null || echo "Database may already exist"

# Enable PostGIS extension
echo "🌍 Enabling PostGIS extension..."
psql -d animal_explorer -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null || echo "PostGIS may already be enabled"

# Setup Python environment
echo "🐍 Setting up Python environment..."
cd backend

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Initialize database
echo "🗃️ Initializing database with sample data..."
python init_db.py

# Create environment file
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your configuration"
fi

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "To start the backend server:"
echo "  cd backend"
echo "  source .venv/bin/activate"
echo "  python run.py"
echo ""
echo "To open the iOS project:"
echo "  open ios/AnimalExplorer/AnimalExplorer.xcodeproj"
echo ""
echo "Happy exploring! 🐾"

