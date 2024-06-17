# Use an official lightweight image
FROM alpine:3.19

# Metadata as labels
LABEL maintainer="Dublok"
LABEL description="A Docker image to capture and list installed packages and their versions in a Docker image."
LABEL org.opencontainers.image.source https://github.com/DockForge/SBOMinify

# Set working directory
WORKDIR /app

# Install required packages and syft in a single layer
RUN apk add --no-cache curl bash jq && \
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin && \
    apk del curl

# Copy the entrypoint script into the container
COPY entrypoint.sh /app/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]