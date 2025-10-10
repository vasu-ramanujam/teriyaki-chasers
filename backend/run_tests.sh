#!/bin/bash
# Script to run tests for the Animal Explorer API

# Set testing environment variable
export TESTING=1
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Activate virtual environment
source ../.venv/bin/activate

# Run tests with specified arguments or all tests
if [ $# -eq 0 ]; then
    echo "Running all tests..."
    python -m pytest tests/ -v
else
    echo "Running tests with arguments: $@"
    python -m pytest "$@"
fi
