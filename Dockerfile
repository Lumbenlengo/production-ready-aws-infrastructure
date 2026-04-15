 FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to /app (where your code actually lives)
WORKDIR /app

# Copy requirements and install
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into /app
COPY app/ .

# Ensure scripts are executable
RUN chmod +x /app/scripts/*.sh

# IMPORTANT: Tell Python that the current directory (/app) is a source of modules
ENV PYTHONPATH=/app

EXPOSE 8000

# Updated CMD to run directly from the /app folder
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
