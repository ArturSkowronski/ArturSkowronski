#!/bin/bash

# PDF Compression Script with Quality Preservation
# Uses Ghostscript to compress PDF files while maintaining high quality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to format file size
format_size() {
    local size=$1
    if [ $size -gt 1073741824 ]; then
        printf "%.1f GB" $(echo "scale=1; $size / 1073741824" | bc -l)
    elif [ $size -gt 1048576 ]; then
        printf "%.1f MB" $(echo "scale=1; $size / 1048576" | bc -l)
    elif [ $size -gt 1024 ]; then
        printf "%.1f KB" $(echo "scale=1; $size / 1024" | bc -l)
    else
        printf "%d B" $size
    fi
}

# Function to compress PDF
compress_pdf() {
    local input_file="$1"
    local output_file="$2"
    local quality="$3"
    
    echo -e "${BLUE}Compressing: ${NC}$input_file"
    
    # Get original file size
    local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file" 2>/dev/null)
    
    # Compress the PDF
    /opt/homebrew/bin/gs \
        -sDEVICE=pdfwrite \
        -dCompatibilityLevel=1.4 \
        -dPDFSETTINGS=/$quality \
        -dNOPAUSE \
        -dQUIET \
        -dBATCH \
        -dColorImageResolution=300 \
        -dGrayImageResolution=300 \
        -dMonoImageResolution=1200 \
        -dColorImageDownsampleType=/Bicubic \
        -dGrayImageDownsampleType=/Bicubic \
        -dMonoImageDownsampleType=/Bicubic \
        -dOptimize=true \
        -sOutputFile="$output_file" \
        "$input_file"
    
    if [ $? -eq 0 ]; then
        # Get compressed file size
        local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        local savings=$((original_size - compressed_size))
        local savings_percent=$((savings * 100 / original_size))
        
        echo -e "${GREEN}✓ Success!${NC}"
        echo -e "  Original:   $(format_size $original_size)"
        echo -e "  Compressed: $(format_size $compressed_size)"
        echo -e "  Saved:      $(format_size $savings) (${savings_percent}%)"
        echo
        
        return 0
    else
        echo -e "${RED}✗ Failed to compress $input_file${NC}"
        echo
        return 1
    fi
}

# Main script
echo -e "${YELLOW}PDF Compression Script${NC}"
echo -e "${YELLOW}=====================${NC}"
echo

# Check if ghostscript is available
if ! command -v /opt/homebrew/bin/gs &> /dev/null; then
    echo -e "${RED}Error: Ghostscript not found at /opt/homebrew/bin/gs${NC}"
    echo "Please install it with: brew install ghostscript"
    exit 1
fi

# Quality settings
echo "Select compression quality:"
echo "1) prepress  - High quality for printing (recommended)"
echo "2) printer   - Good quality for general printing"  
echo "3) ebook     - Medium quality for screen viewing"
echo "4) screen    - Lower quality for web/email"

read -p "Enter choice (1-4, default 1): " quality_choice

case $quality_choice in
    2) quality="printer" ;;
    3) quality="ebook" ;;
    4) quality="screen" ;;
    *) quality="prepress" ;;
esac

echo -e "\nUsing quality setting: ${GREEN}$quality${NC}\n"

# Create compressed directory
compressed_dir="compressed"
if [ ! -d "$compressed_dir" ]; then
    mkdir "$compressed_dir"
    echo -e "Created directory: ${GREEN}$compressed_dir${NC}\n"
fi

# Initialize counters
total_files=0
successful_compressions=0
total_original_size=0
total_compressed_size=0

# Find and compress all PDF files
for pdf_file in *.pdf; do
    if [ -f "$pdf_file" ]; then
        total_files=$((total_files + 1))
        
        # Create output filename
        output_file="$compressed_dir/${pdf_file%.pdf}_compressed.pdf"
        
        # Get original file size for totals
        original_size=$(stat -f%z "$pdf_file" 2>/dev/null || stat -c%s "$pdf_file" 2>/dev/null)
        total_original_size=$((total_original_size + original_size))
        
        # Compress the file
        if compress_pdf "$pdf_file" "$output_file" "$quality"; then
            successful_compressions=$((successful_compressions + 1))
            
            # Add to total compressed size
            compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
            total_compressed_size=$((total_compressed_size + compressed_size))
        fi
    fi
done

# Summary
echo -e "${YELLOW}Compression Summary${NC}"
echo -e "${YELLOW}===================${NC}"

if [ $total_files -eq 0 ]; then
    echo -e "${RED}No PDF files found in current directory${NC}"
else
    echo -e "Total files processed: $total_files"
    echo -e "Successful compressions: ${GREEN}$successful_compressions${NC}"
    
    if [ $successful_compressions -gt 0 ]; then
        total_savings=$((total_original_size - total_compressed_size))
        total_savings_percent=$((total_savings * 100 / total_original_size))
        
        echo -e "Total original size: $(format_size $total_original_size)"
        echo -e "Total compressed size: $(format_size $total_compressed_size)"
        echo -e "Total space saved: ${GREEN}$(format_size $total_savings) (${total_savings_percent}%)${NC}"
        echo
        echo -e "Compressed files are in the '${GREEN}$compressed_dir${NC}' directory"
    fi
fi

echo -e "\n${GREEN}Done!${NC}"