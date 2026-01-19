#!/usr/bin/env bash

set -euo pipefail

# Input variables for script
MEALIE_URL="${1:-$MEALIE_URL}"
API_TOKEN="${2:-$MEALIE_API_TOKEN}"
OUTPUT_DIR="${3:-$MEALIE_EXPORT_DIR}"

if [ -z "$MEALIE_URL" ] || [ -z "$API_TOKEN" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: export_mealie_recipes <mealie_url> <api_token> [output_dir]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Fetching recipe list..."
recipe_list=$(curl -s \
    -H "Authorization: Bearer $API_TOKEN" \
    "$MEALIE_URL/api/recipes")

recipe_ids=$(echo "$recipe_list" | jq -r '.items[].id')

for id in $recipe_ids; do
    echo "Exporting recipe ID: $id"

    recipe_json=$(curl -s \
        -H "Authorization: Bearer $API_TOKEN" \
        "$MEALIE_URL/api/recipes/$id")

    slug=$(echo "$recipe_json" | jq -r '.slug // empty')
    filename="${slug:-recipe_$id}.json"
    if [ -s "$OUTPUT_DIR/$filename" ]; then
      existingRecipeChecksum=$(sha256sum "$OUTPUT_DIR/$filename" | cut -d' ' -f1)
      currentRecipeChecksum=$(sha256sum <(echo "$recipe_json") | cut -d' ' -f1)
      if [ "$currentRecipeChecksum" = "$existingRecipeChecksum" ]; then
        echo "Skipped: $OUTPUT_DIR/$filename"
        continue
      fi
    fi

    echo "$recipe_json" > "$OUTPUT_DIR/$filename"

    echo "Saved: $OUTPUT_DIR/$filename"
done

echo "Export complete."
