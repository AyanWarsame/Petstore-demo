# Multi-stage build for ARM64 compatibility
FROM python:3.9-slim

LABEL maintainer="petstore-demo"
LABEL description="Pet Store Backend - ARM64 Compatible"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install system dependencies - essential for ARM64 compatibility
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc-dev \
        libffi-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Upgrade pip and install setuptools
RUN python -m pip install --upgrade pip setuptools wheel

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create required directories with proper permissions
RUN mkdir -p /app/uploads /app/static/images && \
    chmod -R 755 /app/uploads /app/static

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

EXPOSE 8000

# Use gunicorn with optimized settings
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8000", "--timeout", "60", "--access-logfile", "-", "app:app"]
