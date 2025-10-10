#!/usr/bin/env python3
"""
Generate a visual workflow diagram for the AI identification system
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

def create_workflow_diagram():
    """Create a visual workflow diagram for the AI identification system"""
    
    # Create figure and axis
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    # Define colors
    colors = {
        'client': '#e1f5fe',      # Light blue
        'network': '#f3e5f5',     # Light purple
        'server': '#e8f5e8',      # Light green
        'openai': '#fff3e0',      # Light orange
        'inaturalist': '#e8f5e8', # Light green
        'mock': '#ffebee',        # Light red
        'response': '#f1f8e9'     # Light yellow
    }
    
    # Define components with positions and sizes
    components = [
        # Client side
        {'name': 'iOS App\n📱', 'pos': (1, 10), 'size': (1.5, 1), 'color': colors['client']},
        {'name': 'Photo\n📸', 'pos': (1, 8.5), 'size': (1.5, 1), 'color': colors['client']},
        
        # Network
        {'name': 'Network\n🌐', 'pos': (3.5, 9), 'size': (1.5, 1), 'color': colors['network']},
        
        # Server side
        {'name': 'FastAPI\nServer\n🖥️', 'pos': (6, 10), 'size': (1.5, 1), 'color': colors['server']},
        {'name': 'Image\nProcessing\n🔧', 'pos': (6, 8.5), 'size': (1.5, 1), 'color': colors['server']},
        {'name': 'AI Service\n🧠', 'pos': (6, 7), 'size': (1.5, 1), 'color': colors['server']},
        
        # AI APIs
        {'name': 'OpenAI\nGPT-4\n🤖', 'pos': (2, 5), 'size': (1.5, 1), 'color': colors['openai']},
        {'name': 'iNaturalist\nAPI\n🌿', 'pos': (4, 5), 'size': (1.5, 1), 'color': colors['inaturalist']},
        {'name': 'Mock Data\n🎭', 'pos': (6, 5), 'size': (1.5, 1), 'color': colors['mock']},
        
        # Response
        {'name': 'JSON\nResponse\n📋', 'pos': (8, 7), 'size': (1.5, 1), 'color': colors['response']},
        {'name': 'Display\nResults\n📱', 'pos': (8, 5), 'size': (1.5, 1), 'color': colors['client']},
    ]
    
    # Draw components
    for comp in components:
        x, y = comp['pos']
        w, h = comp['size']
        
        # Create rounded rectangle
        box = FancyBboxPatch(
            (x - w/2, y - h/2), w, h,
            boxstyle="round,pad=0.1",
            facecolor=comp['color'],
            edgecolor='black',
            linewidth=2
        )
        ax.add_patch(box)
        
        # Add text
        ax.text(x, y, comp['name'], ha='center', va='center', 
                fontsize=10, fontweight='bold')
    
    # Draw arrows
    arrows = [
        # Main flow
        ((1.75, 9.5), (2.75, 9.5)),  # iOS to Network
        ((4.25, 9.5), (5.25, 9.5)),  # Network to Server
        ((6, 9.5), (6, 8.5)),        # Server to Image Processing
        ((6, 8), (6, 7)),            # Image Processing to AI Service
        
        # AI Service to APIs
        ((5.25, 7), (2.75, 6)),     # AI Service to OpenAI
        ((5.25, 7), (4.75, 6)),     # AI Service to iNaturalist
        ((5.25, 7), (6.75, 6)),     # AI Service to Mock Data
        
        # APIs to Response
        ((2.75, 4), (7.25, 7.5)),   # OpenAI to Response
        ((4.75, 4), (7.25, 7.5)),   # iNaturalist to Response
        ((6.75, 4), (7.25, 7.5)),   # Mock Data to Response
        
        # Response to Display
        ((8, 6.5), (8, 6)),         # Response to Display
    ]
    
    for start, end in arrows:
        ax.annotate('', xy=end, xytext=start,
                   arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    # Add decision points
    decision_points = [
        {'pos': (3, 6.5), 'text': 'Success?'},
        {'pos': (5, 6.5), 'text': 'Confidence\n≥ 0.8?'},
    ]
    
    for dp in decision_points:
        x, y = dp['pos']
        # Diamond shape for decision
        diamond = patches.Polygon([(x, y+0.3), (x+0.3, y), (x, y-0.3), (x-0.3, y)],
                                facecolor='lightgray', edgecolor='black')
        ax.add_patch(diamond)
        ax.text(x, y, dp['text'], ha='center', va='center', fontsize=8)
    
    # Add title
    ax.text(5, 11.5, 'AI Image Identification Workflow', 
            ha='center', va='center', fontsize=16, fontweight='bold')
    
    # Add legend
    legend_elements = [
        patches.Patch(color=colors['client'], label='Client Side'),
        patches.Patch(color=colors['server'], label='Server Side'),
        patches.Patch(color=colors['openai'], label='OpenAI API'),
        patches.Patch(color=colors['inaturalist'], label='iNaturalist API'),
        patches.Patch(color=colors['mock'], label='Mock Data'),
        patches.Patch(color=colors['response'], label='Response')
    ]
    
    ax.legend(handles=legend_elements, loc='upper right', bbox_to_anchor=(0.98, 0.98))
    
    # Add flow description
    description = """
    Flow Description:
    1. User takes photo in iOS app
    2. Photo sent via network to FastAPI server
    3. Server processes and compresses image
    4. AI Service tries OpenAI GPT-4 Vision first
    5. If OpenAI fails or low confidence, try iNaturalist API
    6. If all APIs fail, return mock data
    7. Return JSON response with species identification
    8. Display results in iOS app
    """
    
    ax.text(0.5, 2, description, fontsize=9, va='top',
            bbox=dict(boxstyle="round,pad=0.5", facecolor='lightgray', alpha=0.8))
    
    plt.tight_layout()
    return fig

def main():
    """Generate and save the workflow diagram"""
    print("Generating AI identification workflow diagram...")
    
    # Create the diagram
    fig = create_workflow_diagram()
    
    # Save as PNG
    fig.savefig('ai_identification_workflow.png', dpi=300, bbox_inches='tight')
    print("✅ Diagram saved as 'ai_identification_workflow.png'")
    
    # Save as SVG (vector format)
    fig.savefig('ai_identification_workflow.svg', bbox_inches='tight')
    print("✅ Diagram saved as 'ai_identification_workflow.svg'")
    
    # Show the plot
    plt.show()
    
    print("\nTo convert to JPG:")
    print("1. Open the PNG file in any image editor")
    print("2. Save as JPG format")
    print("3. Or use command: convert ai_identification_workflow.png ai_identification_workflow.jpg")

if __name__ == "__main__":
    main()




