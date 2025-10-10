# Test Suite for Animal Explorer API

This directory contains comprehensive test cases for the Animal Explorer API, with special focus on the PATCH `/api/sightings/{id}` endpoint.

## Test Structure

```
tests/
├── __init__.py              # Test package initialization
├── conftest.py              # Shared fixtures and test configuration
├── test_sightings_patch.py  # Tests for PATCH /api/sightings/{id}
└── README.md               # This file
```

## Running Tests

### Run all tests
```bash
pytest
```

### Run tests with verbose output
```bash
pytest -v
```

### Run specific test file
```bash
pytest tests/test_sightings_patch.py
```

### Run specific test class
```bash
pytest tests/test_sightings_patch.py::TestPatchSighting
```

### Run specific test
```bash
pytest tests/test_sightings_patch.py::TestPatchSighting::test_update_sighting_location
```

### Run with coverage report
```bash
pytest --cov=app --cov-report=html
```

## Test Coverage

### `test_sightings_patch.py` - PATCH /api/sightings/{id}

#### TestPatchSighting Class (Main functionality tests)

**Successful Update Tests:**
- `test_update_sighting_location` - Update location only
- `test_update_sighting_time` - Update time only
- `test_update_sighting_notes` - Update notes only
- `test_update_sighting_all_fields` - Update all fields simultaneously
- `test_update_sighting_add_notes_to_empty` - Add notes to sighting without notes
- `test_update_sighting_clear_notes` - Clear existing notes

**Error Handling Tests:**
- `test_update_sighting_not_found` - 404 for non-existent sighting
- `test_update_sighting_invalid_location_format` - 400 for invalid location format
- `test_update_sighting_invalid_time_format` - 400 for invalid time format

**Edge Case Tests:**
- `test_update_sighting_empty_request_body` - Empty body doesn't change data
- `test_update_sighting_null_fields` - Null values are handled correctly
- `test_update_sighting_with_timezone` - Different timezone formats
- `test_update_sighting_boundary_coordinates` - Min/max coordinate values
- `test_update_sighting_long_notes` - Very long text in notes
- `test_update_sighting_special_characters_in_notes` - Unicode and special chars
- `test_update_sighting_with_whitespace` - Location with whitespace

**Data Integrity Tests:**
- `test_update_sighting_preserves_other_fields` - Read-only fields unchanged
- `test_update_sighting_multiple_times` - Sequential updates work correctly

#### TestPatchSightingIntegration Class (Integration tests)

- `test_update_then_retrieve` - Updated data can be retrieved
- `test_database_persistence` - Changes persist to database

#### TestPatchSightingEdgeCases Class (Performance & edge cases)

- `test_concurrent_updates_same_sighting` - Rapid successive updates
- `test_update_with_very_precise_coordinates` - High-precision coordinates

## Test Fixtures

### Database Fixtures
- `test_db` - Creates a clean test database for each test
- `client` - FastAPI test client with test database

### Data Fixtures
- `sample_species` - A test species for creating sightings
- `sample_sighting` - A test sighting with notes
- `sample_sighting_no_notes` - A test sighting without notes

## API Endpoint Tested

### PATCH /api/sightings/{id}

**Purpose:** Edit an existing sighting (author only - authentication pending)

**Request Body:**
```json
{
  "location": "lat,lon",    // Optional: "37.7749,-122.4194"
  "time": "ISO8601",        // Optional: "2024-01-15T10:30:00Z"
  "notes": "string"         // Optional: User notes
}
```

**Response:** 200 OK with updated sighting object

**Error Codes:**
- 404 - Sighting not found
- 400 - Invalid request format (bad location/time format)
- 500 - Server error

## Test Data

### Sample Species
- Common Name: "Test Bird"
- Scientific Name: "Testus birdus"

### Sample Sighting
- Location: San Francisco (37.7749, -122.4194)
- Time: 2024-01-15T10:30:00
- Notes: "Initial test notes"

## Notes

- Tests use SQLite in-memory database for speed
- Each test gets a fresh database (function scope)
- GeoAlchemy2 geometry features are disabled for SQLite compatibility
- Tests verify both API responses and database persistence

## Future Enhancements

- [ ] Add authentication tests when auth is implemented
- [ ] Add authorization tests (author-only editing)
- [ ] Add tests for concurrent editing conflicts
- [ ] Add performance benchmarks
- [ ] Add tests for other sighting endpoints (GET, POST, DELETE)
