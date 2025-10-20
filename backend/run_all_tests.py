#!/usr/bin/env python3
"""
Legacy test runner - redirects to the new comprehensive test runner
Use run_comprehensive_tests.py for better results
"""

import subprocess
import sys
from pathlib import Path

def main():
    """Redirect to the comprehensive test runner"""
    print("🔄 Redirecting to comprehensive test runner...")
    print("   (This avoids database conflicts when running all tests together)")
    print()
    
    # Change to backend directory
    backend_dir = Path(__file__).parent
    import os
    os.chdir(backend_dir)
    
    # Run the comprehensive test runner
    try:
        result = subprocess.run([sys.executable, "tests/run_comprehensive_tests.py"], check=True)
        sys.exit(result.returncode)
    except subprocess.CalledProcessError as e:
        print(f"❌ Test runner failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
