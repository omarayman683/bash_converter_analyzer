#!/bin/bash

# Quick Syntax Checker
# Usage: ./quick_syntax_check.sh [directory]

DIR="${1:-.}"

echo "=== Quick Syntax Check ==="
echo "Checking: $DIR"
echo ""

# C Syntax Check
if command -v gcc &> /dev/null; then
    echo "--- C Files ---"
    for file in $(find "$DIR" -name "*.c" -type f ! -path "*/.*"); do
        if gcc -fsyntax-only "$file" &>/dev/null; then
            echo "✓ $(basename "$file")"
        else
            echo "✗ $(basename "$file") - SYNTAX ERRORS"
        fi
    done
fi

# Python Syntax Check
if command -v python3 &> /dev/null; then
    echo ""
    echo "--- Python Files ---"
    for file in $(find "$DIR" -name "*.py" -type f ! -path "*/.*"); do
        if python3 -m py_compile "$file" &>/dev/null; then
            echo "✓ $(basename "$file")"
            rm -f "${file}c"
        else
            echo "✗ $(basename "$file") - SYNTAX ERRORS"
        fi
    done
fi

# Java Syntax Check
if command -v javac &> /dev/null; then
    echo ""
    echo "--- Java Files ---"
    TEMP_DIR=$(mktemp -d)
    for file in $(find "$DIR" -name "*.java" -type f ! -path "*/.*"); do
        if javac -d "$TEMP_DIR" "$file" &>/dev/null; then
            echo "✓ $(basename "$file")"
        else
            echo "✗ $(basename "$file") - SYNTAX ERRORS"
        fi
    done
    rm -rf "$TEMP_DIR"
fi

echo ""
echo "=== Check Complete ==="