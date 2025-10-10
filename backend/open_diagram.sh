#!/bin/bash

echo "🎨 Opening AI Identification Workflow Diagram..."
echo ""
echo "📁 Opening diagram.html in your default browser..."
echo ""

# Open the HTML file in the default browser
if command -v open &> /dev/null; then
    # macOS
    open diagram.html
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open diagram.html
elif command -v start &> /dev/null; then
    # Windows
    start diagram.html
else
    echo "❌ Could not open browser automatically."
    echo "Please open diagram.html in your web browser manually."
fi

echo ""
echo "✅ Diagram opened in browser!"
echo ""
echo "📸 To save as JPG:"
echo "1. Right-click on the diagram in the browser"
echo "2. Select 'Save image as...' or 'Copy image'"
echo "3. Save as PNG first, then convert to JPG"
echo ""
echo "🔄 Alternative: Use Mermaid Live Editor"
echo "1. Go to https://mermaid.live/"
echo "2. Copy the mermaid code from WORKFLOW_MERMAID_DIAGRAM.md"
echo "3. Paste into the editor"
echo "4. Download as PNG"
echo "5. Convert PNG to JPG"




