FROM python:3.11-slim

# Set working directory
WORKDIR /backend

COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose the app port
EXPOSE 8000

# Default command to run the server
CMD ["python", "run.py"]


