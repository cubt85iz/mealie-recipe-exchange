#!/usr/bin/env bash

set -euxo pipefail

MEALIE_URL="${MEALIE_URL:-}"
API_TOKEN="${MEALIE_API_TOKEN:-}"

# Ensure that we have URL & API Token for Mealie.
if [ -z "${MEALIE_URL}" ] || [ -z "${API_TOKEN}" ]; then
    echo "Environment variables MEALIE_URL and MEALIE_API_TOKEN must be set"
    exit 1
fi

# Ensure a single file has been provided.
## Potential Improvement: Allow processing of n files.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <recipe.json>"
    exit 1
fi

FILE="$1"

# Ensure the provided file exists.
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Extract slug from JSON
SLUG=$(jq -r '.slug // empty' "$FILE")

if [ -z "$SLUG" ]; then
    echo "Error: Recipe JSON does not contain a slug"
    exit 1
fi

echo "Processing recipe with slug: $SLUG"

# Update an existing recipe or import a new recipe.
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $API_TOKEN" \
    "$MEALIE_URL/api/recipes/$SLUG")

if [ "$HTTP_CODE" = "200" ]; then
    echo "Recipe exists — updating…"

    curl -s -X PUT \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data @"$FILE" \
        "$MEALIE_URL/api/recipes/$SLUG"

    echo
    echo "Update complete."

else
    echo "Recipe does not exist — creating new…"

    curl -s -X POST \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data @"$FILE" \
        "$MEALIE_URL/api/recipes/import"

    echo
    echo "Import complete."
fi



