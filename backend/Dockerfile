FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Install system dependencies (if any) and build tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . /app

# Ensure upload dir exists
RUN mkdir -p /app/uploads && mkdir -p /app/static/images

EXPOSE 8000

# Use gunicorn for better production behaviour
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "app:app"]
