#!/bin/bash

# Generate Table of Contents from PDF files in media directory
# Creates a markdown table with thumbnails and links to PDFs

SCRIPT_DIR="$(dirname "$0")"
MEDIA_DIR="$SCRIPT_DIR/media"
TOC_FILE="$SCRIPT_DIR/TOC.md"

echo "Generating Table of Contents..."

# Start TOC file
cat > "$TOC_FILE" << 'EOF'
# Table of Contents

| Thumbnail | Title |
| ---------- | ----- |
EOF

# Collect entries and sort by number descending
entries=()

for pdf in "$MEDIA_DIR"/*_compressed.pdf; do
    [ -f "$pdf" ] || continue

    filename=$(basename "$pdf")

    # Extract number prefix (everything before " - ")
    number=$(echo "$filename" | sed 's/ - .*//')

    # Extract title (between "N - " and "_compressed.pdf")
    title=$(echo "$filename" | sed 's/^[0-9]* - //' | sed 's/_compressed\.pdf$//')

    # Check if thumbnail exists
    thumbnail="$number.jpg"
    if [ ! -f "$MEDIA_DIR/$thumbnail" ]; then
        echo "Warning: Missing thumbnail for $filename"
    fi

    # Store entry with number for sorting
    entries+=("$number|$title|$filename|$thumbnail")
done

# Sort entries by number descending and write to TOC
printf '%s\n' "${entries[@]}" | sort -t'|' -k1 -nr | while IFS='|' read -r number title filename thumbnail; do
    echo "| ![$title](./media/$thumbnail) | [$title](<./media/$filename>) |" >> "$TOC_FILE"
done

echo "Generated: $TOC_FILE"
echo "Entries: ${#entries[@]} talks"
