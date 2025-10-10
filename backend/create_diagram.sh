#!/bin/bash

# Create AI Identification Workflow Diagram
echo "🎨 Creating AI Identification Workflow Diagram..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3 first."
    exit 1
fi

# Check if matplotlib is installed
if ! python3 -c "import matplotlib" 2>/dev/null; then
    echo "📦 Installing required packages..."
    pip3 install -r diagram_requirements.txt
fi

# Run the diagram generation script
echo "🚀 Generating diagram..."
python3 generate_diagram.py

# Check if the files were created
if [ -f "ai_identification_workflow.png" ]; then
    echo "✅ PNG diagram created successfully!"
    echo "📁 Files created:"
    echo "   - ai_identification_workflow.png"
    echo "   - ai_identification_workflow.svg"
    echo ""
    echo "🔄 To convert to JPG:"
    echo "   convert ai_identification_workflow.png ai_identification_workflow.jpg"
    echo ""
    echo "📱 To view the diagram:"
    echo "   open ai_identification_workflow.png"
else
    echo "❌ Failed to create diagram. Please check the error messages above."
    exit 1
fi




