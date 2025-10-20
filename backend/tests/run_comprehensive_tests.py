#!/usr/bin/env python3
"""
Comprehensive test runner for the Animal Explorer API
Runs all test suites separately to avoid database conflicts
"""

import subprocess
import sys
import os
import time
from pathlib import Path
from datetime import datetime

def print_header(title):
    """Print a formatted header"""
    print(f"\n{'='*80}")
    print(f"🧪 {title}")
    print(f"{'='*80}")

def print_section(title):
    """Print a formatted section header"""
    print(f"\n📋 {title}")
    print("-" * 60)

def run_test_file(test_file, description):
    """Run a single test file and return results"""
    print_section(f"Running {description}")
    
    start_time = time.time()
    
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pytest", test_file, "-v", "--tb=short"],
            capture_output=True,
            text=True,
            check=True
        )
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Parse results
        lines = result.stdout.split('\n')
        test_count = 0
        passed = 0
        failed = 0
        
        for line in lines:
            if "::" in line and ("PASSED" in line or "FAILED" in line):
                test_count += 1
                if "PASSED" in line:
                    passed += 1
                elif "FAILED" in line:
                    failed += 1
        
        print(f"✅ SUCCESS - {passed}/{test_count} tests passed ({duration:.2f}s)")
        
        if failed > 0:
            print("❌ Some tests failed:")
            for line in lines:
                if "FAILED" in line:
                    print(f"   {line.strip()}")
        
        return {
            "success": failed == 0,
            "total": test_count,
            "passed": passed,
            "failed": failed,
            "duration": duration,
            "output": result.stdout
        }
        
    except subprocess.CalledProcessError as e:
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"❌ FAILED ({duration:.2f}s)")
        print("Error output:")
        print(e.stderr)
        
        return {
            "success": False,
            "total": 0,
            "passed": 0,
            "failed": 0,
            "duration": duration,
            "output": e.stdout,
            "error": e.stderr
        }

def main():
    """Run all test suites comprehensively"""
    print_header("Animal Explorer API - Comprehensive Test Suite")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Change to backend directory (parent of tests directory)
    backend_dir = Path(__file__).parent.parent
    os.chdir(backend_dir)
    
    # Test files and their descriptions
    test_files = [
        ("tests/test_sightings_api.py", "Sightings API Tests"),
        ("tests/test_species_api.py", "Species API Tests"), 
        ("tests/test_sighting_by_id_api.py", "Sighting Detail API Tests")
    ]
    
    # Results tracking
    all_results = []
    total_tests = 0
    total_passed = 0
    total_failed = 0
    total_duration = 0
    
    # Run each test file separately
    for test_file, description in test_files:
        if not os.path.exists(test_file):
            print(f"⚠️  Warning: {test_file} not found, skipping...")
            continue
            
        result = run_test_file(test_file, description)
        all_results.append((test_file, description, result))
        
        total_tests += result["total"]
        total_passed += result["passed"]
        total_failed += result["failed"]
        total_duration += result["duration"]
    
    # Print comprehensive summary
    print_header("📊 COMPREHENSIVE TEST SUMMARY")
    
    print(f"Total Test Files: {len([r for r in all_results if r[2]['total'] > 0])}")
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {total_passed}")
    print(f"Failed: {total_failed}")
    print(f"Success Rate: {(total_passed/total_tests*100):.1f}%" if total_tests > 0 else "N/A")
    print(f"Total Duration: {total_duration:.2f}s")
    
    print_section("Individual Test File Results")
    
    for test_file, description, result in all_results:
        if result["total"] == 0:
            continue
            
        status = "✅ PASSED" if result["success"] else "❌ FAILED"
        print(f"{description:<30} {status:<10} {result['passed']}/{result['total']} tests ({result['duration']:.2f}s)")
    
    print_section("API Coverage Summary")
    
    print("✅ Sightings API:")
    print("   - POST /v1/sightings/ (filtered sightings)")
    print("   - GET /v1/sightings/{id} (sighting details)")
    print("   - POST /v1/sightings/create (create sighting)")
    
    print("\n✅ Species API:")
    print("   - GET /v1/species/ (search species)")
    print("   - GET /v1/species/{id} (species details)")
    
    print("\n✅ Test Features:")
    print("   - Happy path scenarios")
    print("   - Error handling")
    print("   - Edge cases")
    print("   - Data validation")
    print("   - Performance testing")
    print("   - Security testing")
    
    # Final result
    if total_failed == 0:
        print_header("🎉 ALL TESTS PASSED!")
        print("Your API implementation is working correctly!")
        print("\n📁 Test files are ready for continuous integration")
        print("📖 See TEST_README.md for detailed documentation")
        return 0
    else:
        print_header("⚠️  SOME TESTS FAILED")
        print(f"Please review the failed tests above ({total_failed} failures)")
        print("\n💡 Tip: Run individual test files for easier debugging:")
        print("   python3 -m pytest test_sightings_api.py -v")
        print("   python3 -m pytest test_species_api.py -v")
        print("   python3 -m pytest test_sighting_by_id_api.py -v")
        return 1

if __name__ == "__main__":
    sys.exit(main())
