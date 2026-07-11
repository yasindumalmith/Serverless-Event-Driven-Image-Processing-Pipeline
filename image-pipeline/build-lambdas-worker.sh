#!/bin/bash
set -e

LAMBDAS=("presign" "status" "trigger" "resize" "watermark" "rekognition")

for lambda in "${LAMBDAS[@]}"; do
  echo "Building $lambda..."
  cd lambdas/$lambda/src
  npm install --production
  cd ..
  rm -f $lambda.zip
  cd src
  zip -r ../$lambda.zip . -x "*.git*"
  cd ../../..
  echo "Built lambdas/$lambda/$lambda.zip"
done

echo "All Lambdas built successfully"