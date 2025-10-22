# 🧪 Test Suite Documentation

This directory contains comprehensive tests for the Wildlife Explorer Backend API.

## 📋 Test Structure

### Test Files
- `test_sightings_api.py` - Tests for sightings list and creation endpoints
- `test_species_api.py` - Tests for species search and details endpoints  
- `test_sighting_by_id_api.py` - Tests for individual sighting detail endpoint
- `run_comprehensive_tests.py` - Test runner for isolated execution

### Test Categories

#### 🦅 Sightings API Tests
- **List Sightings**: Filtering by location, time, species
- **Create Sighting**: Valid and invalid input handling
- **Error Handling**: Proper HTTP status codes and error messages

#### 🐦 Species API Tests
- **Search Species**: Text-based species search
- **Species Details**: Individual species information retrieval
- **Wikipedia Integration**: External data enrichment

#### 🔍 Sighting Detail Tests
- **Valid Sighting**: Successful retrieval of sighting details
- **Invalid Sighting**: Proper 404 handling for non-existent sightings
- **Private Sightings**: Privacy controls and data filtering

## 🚀 Running Tests

### Quick Start
```bash
# Run all tests with comprehensive isolation
python tests/run_comprehensive_tests.py

# Or use the main test runner
python run_all_tests.py
```

### Individual Test Suites
```bash
# Sightings API
python -m pytest tests/test_sightings_api.py -v

# Species API  
python -m pytest tests/test_species_api.py -v

# Sighting details
python -m pytest tests/test_sighting_by_id_api.py -v
```

### Test Options
```bash
# Verbose output
python -m pytest tests/ -v

# Stop on first failure
python -m pytest tests/ -x

# Run specific test
python -m pytest tests/test_sightings_api.py::test_get_sightings_success -v

# Coverage report
python -m pytest --cov=app tests/
```

## 🏗️ Test Architecture

### Database Isolation
- Each test file runs with its own database
- Tests are completely isolated from each other
- No shared state between test runs

### Test Data
- Sample species data loaded automatically
- Test sightings created as needed
- Clean database state for each test

### Mocking Strategy
- External API calls (Wikipedia) are mocked
- Database operations use test database
- File uploads use temporary storage

## 📊 Test Coverage

### Current Coverage
- **API Endpoints**: 100% coverage
- **Error Handling**: Comprehensive error scenarios
- **Data Validation**: Input validation and sanitization
- **Edge Cases**: Boundary conditions and edge cases

### Test Scenarios

#### ✅ Happy Path Tests
- Valid API requests return expected responses
- Data is properly formatted and structured
- Database operations complete successfully

#### ❌ Error Handling Tests
- Invalid input returns appropriate error codes
- Missing data triggers proper 404 responses
- Server errors are handled gracefully

#### 🔒 Security Tests
- Input validation prevents malicious data
- Private data is properly protected
- Authentication requirements are enforced

## 🛠️ Test Development

### Adding New Tests
1. Create test function with descriptive name
2. Use `@pytest.mark.asyncio` for async tests
3. Follow AAA pattern: Arrange, Act, Assert
4. Include both positive and negative test cases

### Test Data Management
```python
# Create test data
def create_test_sighting(db, species_id):
    sighting = SightingModel(
        species_id=species_id,
        lat=42.3601,
        lon=-71.0589,
        taken_at=datetime.now(timezone.utc)
    )
    db.add(sighting)
    db.commit()
    return sighting
```

### Assertion Patterns
```python
# Response validation
assert response.status_code == 200
assert "items" in response.json()
assert len(response.json()["items"]) > 0

# Data validation
assert sighting["species_id"] == expected_species_id
assert sighting["lat"] == 42.3601
```

## 🐛 Debugging Tests

### Common Issues
1. **Database conflicts**: Ensure test isolation
2. **Import errors**: Check Python path configuration
3. **Async issues**: Use proper async/await patterns

### Debug Commands
```bash
# Run with debug output
python -m pytest tests/ -v -s

# Run single test with debug
python -m pytest tests/test_sightings_api.py::test_get_sightings_success -v -s

# Check test database
python -c "from app.database import engine; print(engine.url)"
```

## 📈 Performance Testing

### Load Testing
- Tests handle multiple concurrent requests
- Database operations are optimized
- Response times are within acceptable limits

### Memory Usage
- Tests clean up after themselves
- No memory leaks in test execution
- Efficient database connection management

## 🔧 Configuration

### Test Environment
- Uses separate test database
- Isolated from production data
- Configurable test settings

### Dependencies
- `pytest`: Main testing framework
- `pytest-asyncio`: Async test support
- `httpx`: HTTP client for API testing
- `sqlalchemy`: Database testing utilities

## 📝 Best Practices

### Test Naming
- Use descriptive function names
- Include test scenario in name
- Follow `test_<functionality>_<scenario>` pattern

### Test Organization
- Group related tests in classes
- Use fixtures for common setup
- Keep tests independent and isolated

### Documentation
- Document complex test scenarios
- Include setup requirements
- Explain expected behavior

---

**Happy Testing! 🧪✨**
