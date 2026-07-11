#!/bin/bash
set -e

echo "Building Sharp Lambda layer for Linux x64..."

# Clean previous builds
rm -rf nodejs
rm -f sharp-layer.zip

# Create the correct layer folder structure
mkdir -p nodejs/node_modules

# Use amazonlinux:2023 which matches the Lambda execution environment
docker run --rm \
  --platform=linux/amd64 \
  -v "$PWD/nodejs":/nodejs \
  amazonlinux:2023 \
  bash -c "
    dnf install -y nodejs npm --quiet && \
    cd /nodejs && \
    npm install --arch=x64 --platform=linux --libc=glibc sharp@0.33.4
  "

# Zip the layer
zip -r sharp-layer.zip nodejs

echo "Done. Layer size: $(du -h sharp-layer.zip | cut -f1)"