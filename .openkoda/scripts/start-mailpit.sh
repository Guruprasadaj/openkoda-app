#!/bin/bash
set -e

exec /usr/local/bin/mailpit \
  --listen 127.0.0.1:8025 \
  --smtp 127.0.0.1:1025
