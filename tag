#!/bin/bash

# Variables
VERSION_FILE="version"
DOCKER_AUTH_FILE=".dockerhub"
IMAGE_NAME="your-docker-image-name"
REGISTRY_URL="docker.io"  # Default Docker Hub
PROD=false  # By default, use staging
INCREMENT="patch"  # Default increment is patch

# Function to handle errors
handle_error() {
    echo "[ERROR] $1"
    exit 1
}

# Function to read the current version from the version file
read_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        echo "[INFO] No version file found. Starting from 0.0.0."
        echo "0.0.0" > "$VERSION_FILE"
    fi
    CURRENT_VERSION=$(cat "$VERSION_FILE")
}

# Function to increment version
increment_version() {
    local version=$1
    local increment_type=$2
    IFS='.' read -r -a version_parts <<< "$version"

    case "$increment_type" in
        major)
            version_parts[0]=$((version_parts[0] + 1))
            version_parts[1]=0
            version_parts[2]=0
            ;;
        minor)
            version_parts[1]=$((version_parts[1] + 1))
            version_parts[2]=0
            ;;
        patch)
            version_parts[2]=$((version_parts[2] + 1))
            ;;
        *)
            handle_error "Unknown increment type: $increment_type"
            ;;
    esac

    NEW_VERSION="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
}

# Function to build and tag Docker image
build_and_tag_image() {
    local version=$1
    local prod=$2

    if [ "$prod" = true ]; then
        TAG="$REGISTRY_URL/$IMAGE_NAME:v$version"
    else
        TAG="$REGISTRY_URL/$IMAGE_NAME:v$version-staging"
    fi

    # Build the Docker image
    docker build -t "$TAG" .
    if [ $? -ne 0 ]; then
        handle_error "Failed to build Docker image."
    fi

    echo "[INFO] Docker image built and tagged as: $TAG"
}

# Function to push Docker image to the registry
push_image() {
    local tag=$1

    # Read authentication from the file
    if [ ! -f "$DOCKER_AUTH_FILE" ]; then
        handle_error "Authentication file '$DOCKER_AUTH_FILE' not found."
    fi

    AUTH_CREDENTIALS=$(cat "$DOCKER_AUTH_FILE")
    USERNAME=$(echo "$AUTH_CREDENTIALS" | cut -d':' -f1)
    AUTH_TOKEN=$(echo "$AUTH_CREDENTIALS" | cut -d':' -f2)

    if [ -z "$USERNAME" ] || [ -z "$AUTH_TOKEN" ]; then
        handle_error "Invalid credentials in '$DOCKER_AUTH_FILE'. Ensure the format is username:token."
    fi

    # Login using the token
    echo "$AUTH_TOKEN" | docker login "$REGISTRY_URL" --username "$USERNAME" --password-stdin
    if [ $? -ne 0 ]; then
        handle_error "Failed to log in to Docker registry."
    fi

    # Push the image
    docker push "$tag"
    if [ $? -ne 0 ]; then
        handle_error "Failed to push Docker image to registry."
    fi

    echo "[INFO] Docker image pushed to: $tag"
}

# Main script execution
main() {
    # Read the current version
    read_version

    # Increment the version
    increment_version "$CURRENT_VERSION" "$INCREMENT"

    # Save the new version to the version file
    echo "$NEW_VERSION" > "$VERSION_FILE"
    echo "[INFO] New version: $NEW_VERSION"

    # Build and tag the Docker image
    build_and_tag_image "$NEW_VERSION" "$PROD"

    # Push the image to the registry
    if [ "$PROD" = true ]; then
        push_image "$REGISTRY_URL/$IMAGE_NAME:v$NEW_VERSION"
    else
        push_image "$REGISTRY_URL/$IMAGE_NAME:v$NEW_VERSION-staging"
    fi

    echo "[INFO] Docker build and push complete."
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --prod) PROD=true ;;  # Use production mode
        --major) INCREMENT="major" ;;  # Increment major version
        --minor) INCREMENT="minor" ;;  # Increment minor version
        -*) echo "[ERROR] Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Start the main script
main

