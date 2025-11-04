#!/bin/bash

# iOS App Icon Generator
# Usage: ./generate_icons.sh input.svg output_directory

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input.svg output_directory"
    exit 1
fi

INPUT_SVG="$1"
OUTPUT_DIR="$2"

if [ ! -f "$INPUT_SVG" ]; then
    echo "Error: Input SVG file not found: $INPUT_SVG"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Array of required sizes (in pixels)
declare -a sizes=(
    "40:Icon-20@2x"
    "60:Icon-20@3x"
    "58:Icon-29@2x"
    "87:Icon-29@3x"
    "80:Icon-40@2x"
    "120:Icon-40@3x"
    "120:Icon-60@2x"
    "180:Icon-60@3x"
    "1024:Icon-1024"
)

echo "Generating iOS app icons from $INPUT_SVG..."

# Check if rsvg-convert is available (from librsvg, install via: brew install librsvg)
if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    for entry in "${sizes[@]}"; do
        IFS=':' read -r size name <<< "$entry"
        output_file="$OUTPUT_DIR/${name}.png"
        rsvg-convert -w "$size" -h "$size" "$INPUT_SVG" -o "$output_file"
        echo "  Created: ${name}.png (${size}x${size})"
    done
# Check if qlmanage is available (built into macOS)
elif command -v qlmanage &> /dev/null && command -v sips &> /dev/null; then
    echo "Using qlmanage + sips (macOS native)..."
    
    # First convert to a large PNG
    temp_png="/tmp/icon_temp.png"
    qlmanage -t -s 2048 -o /tmp "$INPUT_SVG" &> /dev/null
    svg_basename=$(basename "$INPUT_SVG" .svg)
    mv "/tmp/${svg_basename}.svg.png" "$temp_png"
    
    for entry in "${sizes[@]}"; do
        IFS=':' read -r size name <<< "$entry"
        output_file="$OUTPUT_DIR/${name}.png"
        sips -z "$size" "$size" "$temp_png" --out "$output_file" &> /dev/null
        echo "  Created: ${name}.png (${size}x${size})"
    done
    
    rm "$temp_png"
else
    echo "Error: No suitable SVG converter found."
    echo "Please install librsvg: brew install librsvg"
    exit 1
fi

echo ""
echo "✓ All icons generated in: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Open your Xcode project"
echo "2. Navigate to Assets.xcassets"
echo "3. Select AppIcon"
echo "4. Drag the generated PNG files to their corresponding slots"
