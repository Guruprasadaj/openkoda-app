#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_SLUG="${OPENKODA_APP_SLUG:-openkoda}"
ECR_REPO="${OPENKODA_ECR_REPO:-openkoda/app-${APP_SLUG}-monolith}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PLATFORM="${DOCKER_PLATFORM:-linux/arm64,linux/amd64}"

echo "Checking AWS credentials..."
aws sts get-caller-identity >/dev/null

echo "Checking ECR repository: ${ECR_REPO}"
aws ecr describe-repositories --repository-names "${ECR_REPO}" >/dev/null

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

LATEST_NUM="$(aws ecr describe-images \
  --repository-name "${ECR_REPO}" \
  --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' \
  --output json \
  | jq -r 'flatten | map(select(test("^[0-9]+$"))) | map(tonumber) | max // 0')"

NEXT_TAG="$((LATEST_NUM + 1))"
VERSION_URI="${REGISTRY}/${ECR_REPO}:${NEXT_TAG}"
LATEST_URI="${REGISTRY}/${ECR_REPO}:latest"

echo "Publishing tag ${NEXT_TAG}..."

if command -v depot >/dev/null 2>&1; then
  depot build \
    --platform "${PLATFORM}" \
    --no-cache \
    --compress \
    -t "${VERSION_URI}" \
    -t "${LATEST_URI}" \
    -f "${ROOT_DIR}/.openkoda/Dockerfile" \
    --push \
    "${ROOT_DIR}"
else
  echo "depot not found; using docker buildx"
  docker buildx create --use --name openkoda-builder >/dev/null 2>&1 || true
  docker buildx build \
    --platform "${PLATFORM}" \
    --compress \
    -t "${VERSION_URI}" \
    -t "${LATEST_URI}" \
    -f "${ROOT_DIR}/.openkoda/Dockerfile" \
    --push \
    "${ROOT_DIR}"
fi

echo "Published:"
echo "  ${VERSION_URI}"
echo "  ${LATEST_URI}"
