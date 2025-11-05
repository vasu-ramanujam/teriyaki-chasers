#!/usr/bin/env python3
"""
Test script for filtering endpoints
Run this to test the sightings filter API
"""
import requests
import json

BASE_URL = "http://localhost:8000/v1/sightings/"

def test_filter(test_name, request_body):
    """Test a filter request and print results"""
    print(f"\n{'='*60}")
    print(f"TEST: {test_name}")
    print(f"{'='*60}")
    print(f"Request Body: {json.dumps(request_body, indent=2)}")
    
    try:
        response = requests.post(BASE_URL, json=request_body)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Number of results: {len(data.get('items', []))}")
            if data.get('items'):
                print("\nFirst result:")
                print(json.dumps(data['items'][0], indent=2))
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    print("🧪 Testing Sightings Filter API")
    print(f"Base URL: {BASE_URL}")
    print("\nMake sure the backend server is running: python run.py")
    
    # Test cases
    test_cases = [
        {
            "name": "Filter by Username",
            "body": {
                "username": "Ada"
            }
        },
        {
            "name": "Filter by User ID (Recommended)",
            "body": {
                "user_id": "user_001"
            }
        },
        {
            "name": "Filter by Area (Bounding Box)",
            "body": {
                "area": "-122.02,-122.01,37.33,37.34"
            }
        },
        {
            "name": "Filter by Username + Area",
            "body": {
                "username": "Ada",
                "area": "-122.02,-122.01,37.33,37.34"
            }
        },
        {
            "name": "Filter by User ID + Species",
            "body": {
                "user_id": "user_001",
                "species_id": 1
            }
        },
        {
            "name": "Filter by User ID Only (User Dashboard)",
            "body": {
                "user_id": "user_002"
            }
        },
        {
            "name": "Combined Filters",
            "body": {
                "user_id": "user_001",
                "area": "-122.02,-122.01,37.33,37.34",
                "species_id": 1
            }
        }
    ]
    
    for test_case in test_cases:
        test_filter(test_case["name"], test_case["body"])
    
    print(f"\n{'='*60}")
    print("✅ All tests completed!")
    print(f"{'='*60}")

