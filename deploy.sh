#!/usr/bin/env bash
# DocketRadar Website — Deploy to Vercel
# Usage: ./deploy.sh [production|preview]
#
# Requires: VERCEL_TOKEN in /home/opc/.openclaw/workspace/.env

set -euo pipefail

TARGET="${1:-production}"
TEAM_ID="team_0Br8qd93obQDTaxnbFywu4Fj"
PROJECT_NAME="docketradar-website"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load token
VERCEL_TOKEN=$(grep VERCEL_TOKEN /home/opc/.openclaw/workspace/.env | cut -d= -f2)

if [ -z "$VERCEL_TOKEN" ]; then
  echo "Error: VERCEL_TOKEN not found in .env"
  exit 1
fi

echo "Deploying $PROJECT_NAME to $TARGET..."

# Build files array
FILES_JSON="["
FIRST=true

cd "$SCRIPT_DIR"
for filepath in $(find . -type f -not -path './.git/*' -not -name 'deploy.sh' | sort); do
    relpath="${filepath#./}"
    content=$(base64 -w0 "$filepath")

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        FILES_JSON="$FILES_JSON,"
    fi

    FILES_JSON="$FILES_JSON{\"file\":\"$relpath\",\"data\":\"$content\",\"encoding\":\"base64\"}"
done

FILES_JSON="$FILES_JSON]"

# Deploy
RESPONSE=$(curl -s -X POST "https://api.vercel.com/v13/deployments?teamId=$TEAM_ID" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$PROJECT_NAME\",
    \"files\": $FILES_JSON,
    \"target\": \"$TARGET\",
    \"projectSettings\": {
      \"buildCommand\": null,
      \"outputDirectory\": \".\",
      \"framework\": null
    }
  }")

# Parse response
URL=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print('https://'+d.get('url',''))" 2>/dev/null)
STATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('readyState','UNKNOWN'))" 2>/dev/null)

echo "Status: $STATUS"
echo "URL: $URL"
echo ""
echo "Production aliases:"
echo "  https://docketradar-website.vercel.app"
echo ""
echo "Done."
