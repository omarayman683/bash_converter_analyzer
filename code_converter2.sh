#!/bin/bash

# Usage: ./convert_code.sh input_file target_language
# Example: ./convert_code.sh example.py java

if [ $# -lt 2 ]; then
  echo "Usage: $0 <input_file> <target_language>"
  exit 1
fi

INPUT_FILE="$1"
TARGET_LANG=$(echo "$2" | tr '[:upper:]' '[:lower:]')

BASENAME=$(basename "$INPUT_FILE")
FILENAME="${BASENAME%.*}"

# Decide output extension
case "$TARGET_LANG" in
  python) EXT="py" ;;
  java) EXT="java" ;;
  c) EXT="c" ;;
  *) echo "Unsupported target language: $TARGET_LANG"; exit 1 ;;
esac

OUTPUT_FILE="${FILENAME}_converted.${EXT}"

echo "🔄 Converting $INPUT_FILE → $OUTPUT_FILE ($TARGET_LANG)..."

CODE=$(cat "$INPUT_FILE")

# ---- Basic example conversions ----
case "$TARGET_LANG" in
  python)
    # Convert from Java/C to Python (very basic)
    CONVERTED=$(echo "$CODE" \
      | sed 's/public static void main(String args\[\])/:/g' \
      | sed 's/System.out.println/print/g' \
      | sed 's/;//g' \
      | sed 's/{//g' \
      | sed 's/}//g' \
      | sed 's/int /# int /g' \
      | sed 's/return /# return /g' \
      )
    ;;
  java)
    # Convert from Python to Java (very rough)
    CONVERTED=$(echo "$CODE" \
      | sed 's/print(\(.*\))/System.out.println(\1);/g' \
      | sed 's/#.*//g' \
      | sed '1i public class Main { public static void main(String[] args) {' \
      | sed '$a } }' \
      )
    ;;
  c)
    # Convert to C-style (toy example)
    CONVERTED=$(echo "$CODE" \
      | sed 's/print(\(.*\))/printf(\1);/g' \
      | sed '1i #include <stdio.h>\nint main() {' \
      | sed '$a return 0;\n}' \
      )
    ;;
esac

# Save converted code
echo "$CONVERTED" > "$OUTPUT_FILE"
echo "✅ Conversion complete: $OUTPUT_FILE"
