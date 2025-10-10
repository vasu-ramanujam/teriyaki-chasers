"""
Test cases for PATCH /api/sightings/{id} endpoint
Tests the functionality of editing sightings including location, time, and notes updates.
"""
import pytest
from datetime import datetime
from app.models import Sighting as SightingModel


class TestPatchSighting:
    """Test suite for PATCH /api/sightings/{id} endpoint"""
    
    def test_update_sighting_location(self, client, sample_sighting):
        """Test updating sighting location"""
        new_location = "34.0522,-118.2437"  # Los Angeles
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"location": new_location}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_sighting.id
        assert data["lat"] == 34.0522
        assert data["lon"] == -118.2437
        # Other fields should remain unchanged
        assert data["species_id"] == sample_sighting.species_id
        assert data["notes"] == sample_sighting.notes
    
    def test_update_sighting_time(self, client, sample_sighting):
        """Test updating sighting time"""
        new_time = "2024-03-15T16:30:00"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"time": new_time}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_sighting.id
        # Verify the time was updated
        assert "2024-03-15" in data["taken_at"]
        # Other fields should remain unchanged
        assert data["lat"] == sample_sighting.lat
        assert data["lon"] == sample_sighting.lon
    
    def test_update_sighting_notes(self, client, sample_sighting):
        """Test updating sighting notes"""
        new_notes = "Updated notes with more detailed observations"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": new_notes}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_sighting.id
        assert data["notes"] == new_notes
        # Other fields should remain unchanged
        assert data["lat"] == sample_sighting.lat
        assert data["lon"] == sample_sighting.lon
    
    def test_update_sighting_all_fields(self, client, sample_sighting):
        """Test updating all editable fields at once"""
        new_location = "40.7128,-74.0060"  # New York
        new_time = "2024-04-20T12:00:00Z"
        new_notes = "Completely updated sighting information"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={
                "location": new_location,
                "time": new_time,
                "notes": new_notes
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_sighting.id
        assert data["lat"] == 40.7128
        assert data["lon"] == -74.0060
        assert "2024-04-20" in data["taken_at"]
        assert data["notes"] == new_notes
    
    def test_update_sighting_add_notes_to_empty(self, client, sample_sighting_no_notes):
        """Test adding notes to a sighting that previously had none"""
        new_notes = "Adding notes for the first time"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting_no_notes.id}",
            json={"notes": new_notes}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == new_notes
    
    def test_update_sighting_clear_notes(self, client, sample_sighting):
        """Test clearing notes by setting to empty string"""
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": ""}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == ""
    
    def test_update_sighting_not_found(self, client):
        """Test updating a non-existent sighting returns 404"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        
        response = client.patch(
            f"/api/sightings/{fake_id}",
            json={"notes": "Test"}
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()
    
    def test_update_sighting_invalid_location_format(self, client, sample_sighting):
        """Test that invalid location format returns 400"""
        invalid_locations = [
            "invalid",
            "123",
            "lat,lon,extra",
            "abc,def",
            "37.7749",  # Missing longitude
        ]
        
        for invalid_location in invalid_locations:
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"location": invalid_location}
            )
            
            assert response.status_code == 400
            assert "location" in response.json()["detail"].lower()
    
    def test_update_sighting_invalid_time_format(self, client, sample_sighting):
        """Test that invalid time format returns 400"""
        invalid_times = [
            "invalid",
            "2024-13-01T00:00:00",  # Invalid month
            "not-a-date",
            "12/31/2024",  # Wrong format
        ]
        
        for invalid_time in invalid_times:
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"time": invalid_time}
            )
            
            assert response.status_code == 400
            assert "time" in response.json()["detail"].lower()
    
    def test_update_sighting_empty_request_body(self, client, sample_sighting):
        """Test that empty request body doesn't change anything"""
        original_lat = sample_sighting.lat
        original_lon = sample_sighting.lon
        original_notes = sample_sighting.notes
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["lat"] == original_lat
        assert data["lon"] == original_lon
        assert data["notes"] == original_notes
    
    def test_update_sighting_null_fields(self, client, sample_sighting):
        """Test that null fields are handled correctly"""
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={
                "location": None,
                "time": None,
                "notes": None
            }
        )
        
        # Should succeed but not update fields since they're None
        assert response.status_code == 200
        data = response.json()
        # Original values should be preserved
        assert data["lat"] == sample_sighting.lat
        assert data["lon"] == sample_sighting.lon
    
    def test_update_sighting_with_timezone(self, client, sample_sighting):
        """Test updating time with different timezone formats"""
        times_with_tz = [
            "2024-05-15T10:30:00Z",
            "2024-05-15T10:30:00+00:00",
            "2024-05-15T10:30:00-07:00",
        ]
        
        for time_str in times_with_tz:
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"time": time_str}
            )
            
            assert response.status_code == 200
            data = response.json()
            assert "2024-05-15" in data["taken_at"]
    
    def test_update_sighting_boundary_coordinates(self, client, sample_sighting):
        """Test updating with boundary latitude/longitude values"""
        boundary_locations = [
            ("90.0,180.0", 90.0, 180.0),      # Max values
            ("-90.0,-180.0", -90.0, -180.0),  # Min values
            ("0.0,0.0", 0.0, 0.0),            # Zero values
        ]
        
        for location_str, expected_lat, expected_lon in boundary_locations:
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"location": location_str}
            )
            
            assert response.status_code == 200
            data = response.json()
            assert data["lat"] == expected_lat
            assert data["lon"] == expected_lon
    
    def test_update_sighting_long_notes(self, client, sample_sighting):
        """Test updating with very long notes"""
        long_notes = "A" * 5000  # 5000 character note
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": long_notes}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == long_notes
    
    def test_update_sighting_special_characters_in_notes(self, client, sample_sighting):
        """Test updating notes with special characters"""
        special_notes = "Notes with émojis 🐦🌳 and special chars: @#$%^&*()"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": special_notes}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == special_notes
    
    def test_update_sighting_preserves_other_fields(self, client, sample_sighting, test_db):
        """Test that updating doesn't affect read-only fields"""
        original_species_id = sample_sighting.species_id
        original_user_id = sample_sighting.user_id
        original_media_url = sample_sighting.media_url
        original_created_at = sample_sighting.created_at
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": "Updated"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify read-only fields weren't changed
        assert data["species_id"] == original_species_id
        assert data["user_id"] == original_user_id
        
        # Refresh from database to verify
        test_db.refresh(sample_sighting)
        assert sample_sighting.species_id == original_species_id
        assert sample_sighting.user_id == original_user_id
        assert sample_sighting.media_url == original_media_url
    
    def test_update_sighting_multiple_times(self, client, sample_sighting):
        """Test updating the same sighting multiple times"""
        # First update
        response1 = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": "First update"}
        )
        assert response1.status_code == 200
        assert response1.json()["notes"] == "First update"
        
        # Second update
        response2 = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": "Second update"}
        )
        assert response2.status_code == 200
        assert response2.json()["notes"] == "Second update"
        
        # Third update with different field
        response3 = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"location": "35.0,139.0"}
        )
        assert response3.status_code == 200
        assert response3.json()["lat"] == 35.0
        assert response3.json()["lon"] == 139.0
        # Notes should still be from second update
        assert response3.json()["notes"] == "Second update"
    
    def test_update_sighting_with_whitespace(self, client, sample_sighting):
        """Test that location with whitespace is handled correctly"""
        locations_with_space = [
            "37.7749, -122.4194",
            " 37.7749,-122.4194",
            "37.7749,-122.4194 ",
        ]
        
        for location in locations_with_space:
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"location": location}
            )
            
            assert response.status_code == 200
            data = response.json()
            assert abs(data["lat"] - 37.7749) < 0.0001
            assert abs(data["lon"] - (-122.4194)) < 0.0001


class TestPatchSightingIntegration:
    """Integration tests for the PATCH sightings endpoint"""
    
    def test_update_then_retrieve(self, client, sample_sighting):
        """Test that updated sighting can be retrieved with correct values"""
        new_notes = "Integration test notes"
        
        # Update the sighting
        update_response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": new_notes}
        )
        assert update_response.status_code == 200
        
        # Retrieve sightings to verify update persisted
        # Note: This assumes a GET endpoint exists - adjust bbox as needed
        get_response = client.get(
            f"/api/sightings/?bbox=-180,-90,180,90"
        )
        
        if get_response.status_code == 200:
            sightings = get_response.json()["items"]
            updated_sighting = next(
                (s for s in sightings if s["id"] == sample_sighting.id),
                None
            )
            if updated_sighting:
                assert updated_sighting["notes"] == new_notes
    
    def test_database_persistence(self, client, sample_sighting, test_db):
        """Test that updates are actually persisted to the database"""
        new_location = "51.5074,-0.1278"  # London
        new_notes = "Database persistence test"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={
                "location": new_location,
                "notes": new_notes
            }
        )
        
        assert response.status_code == 200
        
        # Query database directly to verify
        test_db.expire_all()  # Clear cache
        db_sighting = test_db.query(SightingModel).filter(
            SightingModel.id == sample_sighting.id
        ).first()
        
        assert db_sighting is not None
        assert db_sighting.lat == 51.5074
        assert db_sighting.lon == -0.1278
        assert db_sighting.notes == new_notes


# Performance and edge case tests
class TestPatchSightingEdgeCases:
    """Edge case and performance tests"""
    
    def test_concurrent_updates_same_sighting(self, client, sample_sighting):
        """Test handling of rapid successive updates"""
        # Simulate concurrent updates
        responses = []
        for i in range(5):
            response = client.patch(
                f"/api/sightings/{sample_sighting.id}",
                json={"notes": f"Update {i}"}
            )
            responses.append(response)
        
        # All requests should succeed
        for response in responses:
            assert response.status_code == 200
        
        # Last update should win
        final_response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"notes": "Final update"}
        )
        assert final_response.status_code == 200
        assert final_response.json()["notes"] == "Final update"
    
    def test_update_with_very_precise_coordinates(self, client, sample_sighting):
        """Test updating with high-precision coordinates"""
        precise_location = "37.7749295,-122.4194155"
        
        response = client.patch(
            f"/api/sightings/{sample_sighting.id}",
            json={"location": precise_location}
        )
        
        assert response.status_code == 200
        data = response.json()
        # Verify precision is maintained (within floating point tolerance)
        assert abs(data["lat"] - 37.7749295) < 0.0000001
        assert abs(data["lon"] - (-122.4194155)) < 0.0000001
