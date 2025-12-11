# Use Python 3.9 with Alpine Linux for a minimal image size
FROM python:3.12-alpine3.20
LABEL maintainer="homeinblock.com"

# Prevent Python from writing .pyc files and ensure output is sent directly to terminal
# Keep Python output unbuffered, this ensures logs are immediately visible in Docker logs
ENV PYTHONUNBUFFERED 1

ARG UID=101

# Copy dependency files first to maximize Docker layer caching
# This allows Docker to cache the pip install step when only code changes
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Bring in scripts and application code
COPY ./scripts /scripts
COPY ./app /app

# Set the working directory to the application folder where Django commands will run
WORKDIR /app

# Expose port 8000 for the Django application
EXPOSE 8000

# Build argument to determine if this is a development build then development dependencies are installed
# Set to 'true' when building for development environment
ARG DEV=false

# Install dependencies and set up the application environment
# All commands are chained to minimize Docker layers
# Create virtual environment and install dependencies
RUN python -m venv /py && \
    # Upgrade pip to the latest version
    /py/bin/pip install --upgrade pip && \
    # Install runtime dependencies (postgres client for DB access, jpeg for image processing)
    apk add --update --no-cache postgresql-client jpeg-dev && \
    # Install temporary build dependencies needed for compiling Python packages
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    # Install Python dependencies from requirements
    /py/bin/pip install -r /tmp/requirements.txt && \
    # Optionally install development-only dependencies (linting, testing tools)
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    # Clean up temporary files to reduce image size
    rm -rf /tmp && \
    # Remove build dependencies to reduce image size (they're no longer needed)
    apk del .tmp-build-deps && \
    # Create a non-root user for running the application (security best practice)
    adduser \
        --uid $UID \
        # --uid ${UID} \
        --disabled-password \
        --no-create-home \
        django-user && \
    # Prepare directories (writable volumes) for static/media assets and scripts
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    # Set ownership of volumes to django-user
    chown -R django-user:django-user /vol/web && \
    # Set permissions on volumes (owner can read/write/execute, others can read/execute)
    chmod -R 755 /vol/web && \
    # Make all scripts executable
    chmod -R +x /scripts

# Put virtualenv and scripts ahead of system binaries in PATH
# This ensures our Python packages and custom scripts are used
ENV PATH="/scripts:/py/bin:$PATH"

# Drop root privileges and switch to a non-root user for security
USER django-user

VOLUME /vol/web/media
VOLUME /vol/web/static

# Entrypoint for the container (defined in scripts/run.sh)
# This script will handle startup tasks like migrations and running the server
CMD ["run.sh"]
