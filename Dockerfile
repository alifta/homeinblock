# Use Python 3.12 with Alpine Linux for a minimal image size
FROM python:3.12-alpine3.20
LABEL maintainer="homeinblock.com"

# Environment variables for Python optimization and logging
# PYTHONUNBUFFERED: Ensures logs are immediately visible in Docker logs
# PYTHONDONTWRITEBYTECODE: Prevents Python from writing .pyc files (reduces image size)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build argument to determine if this is a development build
# Set to 'true' when building for development environment
ARG DEV=false

# Copy dependency files first to maximize Docker layer caching
# This allows Docker to cache the pip install step when only code changes
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Install system dependencies and Python packages
# All commands are chained to minimize Docker layers and reduce final image size
RUN python -m venv /py && \
    # Upgrade pip to the latest version
    /py/bin/pip install --upgrade pip && \
    # Install runtime dependencies (postgres client for DB access, jpeg for image processing)
    apk add --update --no-cache \
        postgresql-client \
        jpeg-dev \
        libpq && \
    # Install temporary build dependencies needed for compiling Python packages
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base \
        postgresql-dev \
        musl-dev \
        zlib-dev \
        linux-headers && \
    # Install Python dependencies from requirements
    /py/bin/pip install -r /tmp/requirements.txt && \
    # Optionally install development-only dependencies (linting, testing tools)
    if [ "$DEV" = "true" ]; then \
        /py/bin/pip install -r /tmp/requirements.dev.txt; \
    fi && \
    # Clean up temporary files to reduce image size
    rm -rf /tmp && \
    # Remove build dependencies to reduce image size (they're no longer needed)
    apk del .tmp-build-deps && \
    # Create a non-root user for running the application (security best practice)
    adduser \
        --disabled-password \
        --no-create-home \
        django-user && \
    # Prepare directories (writable volumes) for static/media assets
    mkdir -p /vol/web/media /vol/web/static && \
    # Set ownership of volumes to django-user
    chown -R django-user:django-user /vol && \
    # Set permissions on volumes (owner can read/write/execute, others can read/execute)
    chmod -R 755 /vol

# Copy scripts and make them executable
COPY ./scripts /scripts
RUN chmod -R +x /scripts

# Set the working directory to the application folder where Django commands will run
WORKDIR /app

# Copy application code (done after dependencies to leverage layer caching)
COPY --chown=django-user:django-user ./app /app

# Put virtualenv and scripts ahead of system binaries in PATH
# This ensures our Python packages and custom scripts are used
ENV PATH="/scripts:/py/bin:$PATH"

# Expose port 8000 for the Django application
EXPOSE 8000

# Drop root privileges and switch to a non-root user for security
USER django-user

# Health check to ensure the application is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

# Entrypoint for the container (defined in scripts/run.sh)
# This script will handle startup tasks like migrations and running the server
CMD ["run.sh"]
