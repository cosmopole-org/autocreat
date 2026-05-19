#!/usr/bin/env bash
# Runs the AutoCreat API test suite via Newman.
# Bypasses any http_proxy/https_proxy env vars that would route through a local proxy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTION="$SCRIPT_DIR/autocreat_api_collection.json"
BASE_URL="${BASE_URL:-http://localhost:8081}"

echo "=== AutoCreat API Test Suite ==="
echo "Base URL: $BASE_URL"
echo ""

no_proxy="localhost,127.0.0.1" \
http_proxy="" \
https_proxy="" \
  newman run "$COLLECTION" \
  --env-var "baseUrl=$BASE_URL" \
  --reporters cli
