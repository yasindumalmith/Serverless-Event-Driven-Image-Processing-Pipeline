#!/bin/bash
set -e

echo "Building Sharp Lambda layer for Linux x64..."

# Clean previous builds
rm -rf nodejs
rm -f sharp-layer.zip

# Create the layer structure
# Lambda layers for Node.js must put libraries in nodejs/node_modules/
mkdir -p nodejs

# Use Docker to install sharp for the Lambda runtime
docker run --rm \
  --platform=linux/amd64 \
  -v "$PWD/nodejs":/var/task \
  public.ecr.aws/lambda/nodejs:20 \
  /bin/bash -c "
    cd /var/task && \
    npm init -y && \
    npm install --arch=x64 --platform=linux --libc=glibc sharp
  "

# Zip it up
zip -r sharp-layer.zip nodejs > /dev/null

echo "Built sharp-layer.zip ($(du -h sharp-layer.zip | cut -f1))"