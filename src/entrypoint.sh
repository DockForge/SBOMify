#!/bin/bash

set -e

# Function to parse image and extract organization, repository, and tag
parse_image() {
  local image=$1
  local organization
  local repository
  local tag

  if [[ $image =~ ^([^/]+)\.([^/]+)/([^/]+)/([^:]+):(.+)$ ]]; then
    # Handle ghcr.io or other registry with organization/owner
    registry="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    organization=${BASH_REMATCH[3]}
    repository=${BASH_REMATCH[4]}
    tag=${BASH_REMATCH[5]}
  elif [[ $image =~ ^([^/]+)/([^/]+):(.+)$ ]]; then
    # Handle docker hub or similar with organization/owner
    organization=${BASH_REMATCH[1]}
    repository=${BASH_REMATCH[2]}
    tag=${BASH_REMATCH[3]}
  elif [[ $image =~ ^([^/]+)/([^/]+)$ ]]; then
    # Handle docker hub or similar without tag (default to latest)
    organization=${BASH_REMATCH[1]}
    repository=${BASH_REMATCH[2]}
    tag="latest"
  elif [[ $image =~ ^([^/]+):(.+)$ ]]; then
    # Handle library images with tag
    organization="library"
    repository=${BASH_REMATCH[1]}
    tag=${BASH_REMATCH[2]}
  else
    # Handle library images without tag (default to latest)
    organization="library"
    repository=${image}
    tag="latest"
  fi

  echo "$organization $repository $tag"
}

# Function to scan images
scan_images() {
  IFS=',' read -ra IMAGES <<< "$IMAGES"
  for image in "${IMAGES[@]}"; do
    echo "Processing image: $image"
    read -r ORGANIZATION REPOSITORY TAG <<< "$(parse_image $image)"

    ORGANIZATION=${ORGANIZATION//\//_}  # Replace slashes with underscores
    REPOSITORY=${REPOSITORY//\//_}      # Replace slashes with underscores
    TAG=${TAG//\//_}                    # Replace slashes with underscores

    filename=$(echo "$FILE_NAME" | sed "s|\\[ORGANIZATION\\]|$ORGANIZATION|g" | sed "s|\\[REPOSITORY\\]|$REPOSITORY|g" | sed "s|\\[TAG\\]|$TAG|g")
    filename="${FILE_PREFIX}${filename}${FILE_SUFFIX}"

    echo "Generated filename: $filename"

    syft $image --scope all-layers -o syft-table > "${OUTPUT_PATH}/${filename}.txt"
    syft $image --scope all-layers -o json | jq '.' > "${OUTPUT_PATH}/${filename}.json"
    echo "Created files: ${OUTPUT_PATH}/${filename}.txt and ${OUTPUT_PATH}/${filename}.json"
  done
}

# Function to clean up output directory on error
cleanup() {
  echo "An error occurred. Cleaning up output directory..."
  rm -rf "${OUTPUT_PATH:?}"/*
}

# Trap errors and execute cleanup
trap cleanup ERR

# Start Docker daemon in the background
dockerd-entrypoint.sh &

# Wait for Docker daemon to start
until docker info > /dev/null 2>&1; do
  sleep 1
done

# Default values for optional parameters
OUTPUT_PATH=${OUTPUT_PATH:-"/output"}
FILE_PREFIX=${FILE_PREFIX:-""}
FILE_SUFFIX=${FILE_SUFFIX:-""}
FILE_NAME=${FILE_NAME:-"[ORGANIZATION]_[REPOSITORY]_[TAG]"}

# Debugging info
echo "Initial environment variables:"
echo "IMAGES: $IMAGES"
echo "OUTPUT_PATH: $OUTPUT_PATH"
echo "FILE_PREFIX: $FILE_PREFIX"
echo "FILE_SUFFIX: $FILE_SUFFIX"
echo "FILE_NAME: $FILE_NAME"

# Check required parameters
if [ -z "$IMAGES" ]; then
  echo "Error: IMAGES environment variable is required."
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_PATH"

# Debugging info after setting defaults
echo "Final environment variables after defaulting:"
echo "IMAGES: $IMAGES"
echo "OUTPUT_PATH: $OUTPUT_PATH"
echo "FILE_PREFIX: $FILE_PREFIX"
echo "FILE_SUFFIX: $FILE_SUFFIX"
echo "FILE_NAME: $FILE_NAME"

# Scan the images
scan_images

# List the output directory for debugging
ls -la "$OUTPUT_PATH"

# Stop Docker daemon if there are any running containers
running_containers=$(docker ps -q)
if [ -n "$running_containers" ]; then
  docker kill $running_containers
else
  echo "No running containers to kill."
fi
