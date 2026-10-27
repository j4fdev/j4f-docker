#!/usr/bin/env bash
set -e

IMAGE_NAME="ghcr.io/j4fdev/flutter-builder:stable"

echo "==> Construyendo imagen $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" -f Dockerfile .

echo "==> Verificando instalacion de Flutter..."
docker run --rm "$IMAGE_NAME" flutter --version

echo "==> Imagen lista: $IMAGE_NAME"
