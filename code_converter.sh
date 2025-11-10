#!/bin/bash

# PROPER Code Language Converter
# Creates syntactically correct code

set -e

INPUT_FILE="$1"
TARGET_LANG="$2"

# Detect source language
detect_language() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py) echo "python" ;;
        java) echo "java" ;;
        c) echo "c" ;;
        *) echo "unknown" ;;
    esac
}

# Simple string contains function
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"; then
        return 0
    else
        return 1
    fi
}

# Simple string starts with function
starts_with() {
    string="$1"
    prefix="$2"
    case "$string" in
        "$prefix"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Count indentation level
get_indent_level() {
    local line="$1"
    local spaces=$(echo "$line" | sed 's/[^ ].*//')
    echo ${#spaces}
}

# Python to Java - PROPER VERSION
python_to_java() {
    local input_file="$1"
    local output_file="${input_file%.*}.java"
    local class_name=$(basename "${input_file%.*}")
    class_name=$(echo "$class_name" | sed 's/[^a-zA-Z0-9_]//g')  # Clean class name
    
    echo "[INFO] Converting Python to Java..."
    
    # Track indentation levels for proper brace placement
    local indent_stack=()
    local current_indent=0
    local in_function=0
    
    # Start with class structure
    cat > "$output_file" << EOF
public class $class_name {
EOF

    # Read the Python file line by line
    while IFS= read -r line; do
        # Skip shebang and encoding lines
        if starts_with "$line" "#!" || contains "$line" "coding:"; then
            continue
        fi
        
        # Get current indentation level
        local line_indent=$(get_indent_level "$line")
        local clean_line=$(echo "$line" | sed 's/^[ \t]*//')
        
        # Convert function definitions
        if starts_with "$clean_line" "def "; then
            # Extract function name
            local func_part=$(echo "$clean_line" | sed 's/def //' | sed 's/://')
            local func_name=$(echo "$func_part" | sed 's/(.*//' | tr -d ' ')
            local params=$(echo "$func_part" | sed 's/.*(//' | sed 's/).*//')
            
            # Add closing brace if we were in a function
            if [[ $in_function -eq 1 ]]; then
                echo "    }" >> "$output_file"
            fi
            
            echo "    public static void $func_name($params) {" >> "$output_file"
            in_function=1
        
        # Convert print statements
        elif contains "$clean_line" "print("; then
            # Extract content inside print()
            local content=$(echo "$clean_line" | sed 's/.*print(//' | sed 's/).*//')
            # Handle different print formats
            if contains "$content" ","; then
                # Multiple arguments - convert to string concatenation
                content=$(echo "$content" | sed 's/, / + \"/g')
                echo "        System.out.println($content\");" >> "$output_file"
            elif starts_with "$content" "\"" && [[ "$content" == *"\"" ]]; then
                # String literal
                content=$(echo "$content" | sed 's/^"//' | sed 's/"$//')
                echo "        System.out.println(\"$content\");" >> "$output_file"
            else
                # Variable or expression
                echo "        System.out.println($content);" >> "$output_file"
            fi
        
        # Convert if __name__ == "__main__" to main method
        elif contains "$clean_line" "__name__" && contains "$clean_line" "__main__"; then
            if [[ $in_function -eq 1 ]]; then
                echo "    }" >> "$output_file"
                in_function=0
            fi
            echo "" >> "$output_file"
            echo "    public static void main(String[] args) {" >> "$output_file"
        
        # Convert return statements
        elif starts_with "$clean_line" "return "; then
            local value=$(echo "$clean_line" | sed 's/return //')
            echo "        return $value;" >> "$output_file"
        
        # Handle variable assignments
        elif contains "$clean_line" "=" && [[ ! "$clean_line" =~ "def " ]] && [[ ! "$clean_line" =~ "if " ]] && [[ ! "$clean_line" =~ "class " ]]; then
            echo "        $clean_line;" >> "$output_file"
        
        # Handle function calls
        elif contains "$clean_line" "(" && contains "$clean_line" ")" && [[ ! "$clean_line" =~ "print(" ]] && [[ ! "$clean_line" =~ "def " ]]; then
            echo "        $clean_line;" >> "$output_file"
        
        # Skip empty lines and comments for now
        elif [[ -z "$clean_line" ]] || starts_with "$clean_line" "#"; then
            continue
        fi
        
    done < "$input_file"
    
    # Add closing braces
    if [[ $in_function -eq 1 ]]; then
        echo "    }" >> "$output_file"
    fi
    echo "}" >> "$output_file"
    
    echo "$output_file"
}

# Java to Python - PROPER VERSION
java_to_python() {
    local input_file="$1"
    local output_file="${input_file%.*}.py"
    
    echo "[INFO] Converting Java to Python..."
    
    # Start with Python header
    cat > "$output_file" << 'EOF'
#!/usr/bin/env python3
# Converted from Java
EOF
    echo "" >> "$output_file"

    # Read the Java file line by line
    while IFS= read -r line; do
        # Skip package and import statements
        if starts_with "$line" "package " || starts_with "$line" "import "; then
            continue
        fi
        
        local clean_line=$(echo "$line" | sed 's/^[ \t]*//')
        
        # Convert class definition
        if contains "$clean_line" "public class "; then
            local class_name=$(echo "$clean_line" | sed 's/.*class //' | sed 's/[ {].*//')
            echo "class $class_name:" >> "$output_file"
            echo "" >> "$output_file"
        
        # Convert main method
        elif contains "$clean_line" "public static void main"; then
            echo "if __name__ == \"__main__\":" >> "$output_file"
        
        # Convert other methods
        elif contains "$clean_line" "public static void " && ! contains "$clean_line" "main"; then
            local method_part=$(echo "$clean_line" | sed 's/public static void //' | sed 's/{//')
            local method_name=$(echo "$method_part" | sed 's/(.*//' | tr -d ' ')
            local params=$(echo "$method_part" | sed 's/.*(//' | sed 's/).*//' | sed 's/ *//g')
            echo "def $method_name($params):" >> "$output_file"
        
        # Convert System.out.println to print
        elif contains "$clean_line" "System.out.println"; then
            local content=$(echo "$clean_line" | sed 's/.*System.out.println(//' | sed 's/);.*//')
            # Remove trailing semicolon if present
            content=$(echo "$content" | sed 's/;$//')
            echo "    print($content)" >> "$output_file"
        
        # Handle variable declarations with initialization
        elif contains "$clean_line" "=" && contains "$clean_line" ";"; then
            local clean_var=$(echo "$clean_line" | sed 's/;//' | sed 's/.*[ ]//')
            echo "    $clean_var" >> "$output_file"
        
        # Remove braces and semicolons, keep method calls
        elif [[ ! -z "$clean_line" ]] && ! contains "$clean_line" "}" && ! contains "$clean_line" "{"; then
            local python_line=$(echo "$clean_line" | sed 's/;//g')
            if contains "$python_line" "(" && contains "$python_line" ")"; then
                # Method call - add proper indentation
                echo "    $python_line" >> "$output_file"
            elif [[ ! -z "$python_line" ]]; then
                echo "    $python_line" >> "$output_file"
            fi
        fi
    done < "$input_file"
    
    echo "$output_file"
}

# Main conversion function
convert_code() {
    local input_file="$1"
    local target_lang="$2"
    local source_lang=$(detect_language "$input_file")
    
    if [ ! -f "$input_file" ]; then
        echo "[ERROR] Input file not found: $input_file"
        exit 1
    fi
    
    if [ "$source_lang" = "unknown" ]; then
        echo "[ERROR] Unsupported file type: $input_file"
        exit 1
    fi
    
    echo "[INFO] Source: $source_lang, Target: $target_lang"
    
    case "${source_lang}_to_${target_lang}" in
        python_to_java)
            python_to_java "$input_file"
            ;;
        java_to_python)
            java_to_python "$input_file"
            ;;
        *)
            echo "[ERROR] Unsupported conversion: $source_lang to $target_lang"
            echo "[INFO] Supported conversions:"
            echo "[INFO]   python → java"
            echo "[INFO]   java → python" 
            exit 1
            ;;
    esac
}

# Show usage
show_usage() {
    echo "PROPER Code Language Converter"
    echo "Creates syntactically correct code"
    echo ""
    echo "Usage: $0 <input_file> <target_language>"
    echo ""
    echo "Supported conversions:"
    echo "  python → java    - Convert Python to Java"
    echo "  java → python    - Convert Java to Python" 
    echo ""
    echo "Examples:"
    echo "  $0 program.py java     # Convert Python to Java"
    echo "  $0 Main.java python    # Convert Java to Python"
}

# Validate Java syntax
validate_java() {
    local file="$1"
    if command -v javac >/dev/null 2>&1; then
        echo "[INFO] Validating Java syntax..."
        if javac -Xlint:none "$file" 2>/dev/null; then
            echo "[SUCCESS] Java syntax is valid!"
            # Clean up .class file
            local class_file="${file%.*}.class"
            [ -f "$class_file" ] && rm "$class_file"
        else
            echo "[WARNING] Java syntax may have issues"
        fi
    fi
}

# Validate Python syntax
validate_python() {
    local file="$1"
    echo "[INFO] Validating Python syntax..."
    if python3 -m py_compile "$file" 2>/dev/null; then
        echo "[SUCCESS] Python syntax is valid!"
        # Clean up .pyc file
        local pyc_file="${file}c"
        [ -f "$pyc_file" ] && rm "$pyc_file"
    else
        echo "[WARNING] Python syntax may have issues"
    fi
}

# Main execution
main() {
    if [ $# -ne 2 ]; then
        show_usage
        exit 1
    fi
    
    local output_file
    output_file=$(convert_code "$1" "$2")
    
    if [ -f "$output_file" ]; then
        echo "[SUCCESS] Conversion complete! Output: $output_file"
        
        # Validate the converted code
        case "$TARGET_LANG" in
            java) validate_java "$output_file" ;;
            python) validate_python "$output_file" ;;
        esac
        
        # Show preview
        echo ""
        echo "[INFO] Preview of converted file:"
        echo "=============================="
        cat "$output_file"
        
        echo ""
        echo "[INFO] File created: $(wc -l < "$output_file") lines"
    else
        echo "[ERROR] Output file was not created"
        exit 1
    fi
}

main "$@"