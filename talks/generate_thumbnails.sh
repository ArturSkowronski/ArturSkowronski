#!/bin/bash

# Generate thumbnail images from the first slide of PDF files in media directory
# Thumbnails are named based on the number prefix of the PDF (e.g., "11 - Talk Name.pdf" -> "11.jpg")

MEDIA_DIR="$(dirname "$0")/media"
THUMBNAIL_WIDTH=800

echo "Generating thumbnails for PDFs in $MEDIA_DIR"

for pdf in "$MEDIA_DIR"/*_compressed.pdf; do
    [ -f "$pdf" ] || continue

    filename=$(basename "$pdf")
    # Extract number prefix (everything before " - ")
    number=$(echo "$filename" | sed 's/ - .*//')

    thumbnail="$MEDIA_DIR/${number}.jpg"

    if [ -f "$thumbnail" ]; then
        echo "Skipping $filename (thumbnail exists)"
        continue
    fi

    echo "Generating thumbnail for: $filename -> ${number}.jpg"

    # Convert first page of PDF to JPG using pdftoppm
    # -f 1 -l 1: first page only, -jpeg: output format, -scale-to: width
    pdftoppm -f 1 -l 1 -jpeg -scale-to $THUMBNAIL_WIDTH "$pdf" "$MEDIA_DIR/${number}_temp"

    # pdftoppm adds page number suffix (e.g., -001.jpg), rename to final name
    temp_file=$(ls "$MEDIA_DIR/${number}_temp"*.jpg 2>/dev/null | head -1)
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
        mv "$temp_file" "$thumbnail"
        echo "Created: $thumbnail"
    else
        echo "Error: Failed to generate thumbnail for $filename"
    fi
done

echo "Done!"
