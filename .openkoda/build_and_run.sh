#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="${OPENKODA_IMAGE_TAG:-openkoda-monolith:1.7.1}"
CONTAINER_NAME="${OPENKODA_CONTAINER_NAME:-openkoda-monolith}"
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

echo "Building ${IMAGE_TAG} (platform: ${PLATFORM})..."
docker build \
  --platform "${PLATFORM}" \
  -t "${IMAGE_TAG}" \
  -f "${ROOT_DIR}/.openkoda/Dockerfile" \
  "${ROOT_DIR}"

echo "Starting container ${CONTAINER_NAME}..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d \
  --name "${CONTAINER_NAME}" \
  --platform "${PLATFORM}" \
  -p 8080:8080 \
  -p 8025:8025 \
  -p 1025:1025 \
  "${IMAGE_TAG}"

echo ""
echo "Openkoda UI : http://localhost:8080"
echo "Mailpit UI  : http://localhost:8025"
echo "Login       : admin / admin123"
echo ""
echo "Follow logs: docker logs -f ${CONTAINER_NAME}"
