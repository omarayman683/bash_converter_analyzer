#!/bin/bash

# Enhanced Syntax Checker with Detailed Analysis
# Usage: ./enhanced_syntax_check.sh [directory]

DIR="${1:-.}"

echo "=== Enhanced Syntax Analysis ==="
echo "Checking: $DIR"
echo ""

# Count functions in a file
count_functions() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py)
            # Count Python functions (def statements)
            grep -c "^def " "$file" 2>/dev/null || echo "0"
            ;;
        java)
            # Count Java methods (public/private/protected methods)
            grep -E -c "^(public|private|protected).*\([^)]*\)\s*\{?$" "$file" 2>/dev/null || echo "0"
            ;;
        c)
            # Count C functions (return_type function_name(parameters))
            grep -E -c "^[a-zA-Z_][a-zA-Z0-9_* ]+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*\{?$" "$file" 2>/dev/null || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Count classes in a file
count_classes() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py)
            # Count Python classes
            grep -c "^class " "$file" 2>/dev/null || echo "0"
            ;;
        java)
            # Count Java classes
            grep -c "^class " "$file" 2>/dev/null || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Count imports/includes
count_imports() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py)
            # Count Python imports
            grep -c "^import\|^from" "$file" 2>/dev/null || echo "0"
            ;;
        java)
            # Count Java imports
            grep -c "^import" "$file" 2>/dev/null || echo "0"
            ;;
        c)
            # Count C includes
            grep -c "^#include" "$file" 2>/dev/null || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Count comments in a file
count_comments() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py)
            # Count Python comments (#)
            grep -c "^#\|[[:space:]]+#" "$file" 2>/dev/null || echo "0"
            ;;
        java|c)
            # Count Java/C comments (// and /* */)
            grep -c "//\|/\*" "$file" 2>/dev/null || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if command -v stat &> /dev/null; then
        stat -c%s "$file" 2>/dev/null | awk '{
            if ($1 >= 1024*1024) printf "%.1f MB", $1/1024/1024
            else if ($1 >= 1024) printf "%.1f KB", $1/1024
            else printf "%d B", $1
        }' || echo "0 B"
    else
        # Fallback for systems without stat
        wc -c < "$file" | awk '{
            if ($1 >= 1024*1024) printf "%.1f MB", $1/1024/1024
            else if ($1 >= 1024) printf "%.1f KB", $1/1024
            else printf "%d B", $1
        }'
    fi
}

# Analyze a single file
analyze_file() {
    local file="$1"
    local ext="${file##*.}"
    local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
    local functions=$(count_functions "$file")
    local classes=$(count_classes "$file")
    local imports=$(count_imports "$file")
    local comments=$(count_comments "$file")
    local size=$(get_file_size "$file")
    
    echo "  📄 $(basename "$file")"
    echo "     📏 Lines: $lines"
    echo "     ⚙️  Functions: $functions"
    echo "     🏛️  Classes: $classes"
    echo "     📦 Imports: $imports"
    echo "     💬 Comments: $comments"
    echo "     📊 Size: $size"
}

# C Syntax Check with Analysis
if command -v gcc &> /dev/null; then
    echo "--- C Files Analysis ---"
    c_files=$(find "$DIR" -name "*.c" -type f ! -path "*/.*")
    if [ -n "$c_files" ]; then
        for file in $c_files; do
            if gcc -fsyntax-only "$file" &>/dev/null; then
                echo "✅ $(basename "$file") - Syntax OK"
                analyze_file "$file"
            else
                echo "❌ $(basename "$file") - SYNTAX ERRORS"
                analyze_file "$file"
                # Show first error
                echo "     🔍 First error:"
                gcc -fsyntax-only "$file" 2>&1 | head -1 | sed 's/^/       /'
            fi
            echo ""
        done
    else
        echo "No C files found"
    fi
fi

# Python Syntax Check with Analysis
if command -v python3 &> /dev/null; then
    echo ""
    echo "--- Python Files Analysis ---"
    py_files=$(find "$DIR" -name "*.py" -type f ! -path "*/.*")
    if [ -n "$py_files" ]; then
        for file in $py_files; do
            if python3 -m py_compile "$file" &>/dev/null; then
                echo "✅ $(basename "$file") - Syntax OK"
                analyze_file "$file"
                rm -f "${file}c" 2>/dev/null
            else
                echo "❌ $(basename "$file") - SYNTAX ERRORS"
                analyze_file "$file"
                # Show first error
                echo "     🔍 First error:"
                python3 -m py_compile "$file" 2>&1 | head -1 | sed 's/^/       /'
            fi
            echo ""
        done
    else
        echo "No Python files found"
    fi
fi

# Java Syntax Check with Analysis
if command -v javac &> /dev/null; then
    echo ""
    echo "--- Java Files Analysis ---"
    java_files=$(find "$DIR" -name "*.java" -type f ! -path "*/.*")
    if [ -n "$java_files" ]; then
        TEMP_DIR=$(mktemp -d)
        for file in $java_files; do
            if javac -d "$TEMP_DIR" "$file" &>/dev/null; then
                echo "✅ $(basename "$file") - Syntax OK"
                analyze_file "$file"
            else
                echo "❌ $(basename "$file") - SYNTAX ERRORS"
                analyze_file "$file"
                # Show first error
                echo "     🔍 First error:"
                javac -d "$TEMP_DIR" "$file" 2>&1 | head -1 | sed 's/^/       /'
            fi
            echo ""
        done
        rm -rf "$TEMP_DIR"
    else
        echo "No Java files found"
    fi
fi

# Summary Statistics
echo ""
echo "=== Summary Statistics ==="
total_files=0
total_lines=0
total_functions=0
total_classes=0

# Calculate totals
for file in $(find "$DIR" -name "*.py" -o -name "*.java" -o -name "*.c" -type f ! -path "*/.*"); do
    total_files=$((total_files + 1))
    total_lines=$((total_lines + $(wc -l < "$file" 2>/dev/null || echo 0)))
    total_functions=$((total_functions + $(count_functions "$file")))
    total_classes=$((total_classes + $(count_classes "$file")))
done

echo "📁 Total Files: $total_files"
echo "📏 Total Lines: $total_lines"
echo "⚙️  Total Functions: $total_functions"
echo "🏛️  Total Classes: $total_classes"

# Language breakdown
echo ""
echo "--- Language Breakdown ---"
for lang in py java c; do
    count=$(find "$DIR" -name "*.$lang" -type f ! -path "*/.*" | wc -l)
    if [ "$count" -gt 0 ]; then
        case "$lang" in
            py) echo "🐍 Python: $count files" ;;
            java) echo "☕ Java: $count files" ;;
            c) echo "🔧 C: $count files" ;;
        esac
    fi
done

echo ""
echo "=== Analysis Complete ==="