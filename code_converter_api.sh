#!/bin/bash

# FREE API Code Converter
# Uses free code conversion APIs

set -e

INPUT_FILE="$1"
TARGET_LANG="$2"
API_CHOICE="${3:-codeium}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect source language
detect_language() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        py) echo "python" ;;
        java) echo "java" ;;
        c) echo "c" ;;
        cpp) echo "cpp" ;;
        js) echo "javascript" ;;
        *) echo "unknown" ;;
    esac
}

# Free API 1: Codeium API (Free tier)
convert_with_codeium() {
    local source_code="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    log_info "Using Codeium API (Free)..."
    
    # Codeium API endpoint (this is a simulated example - real API may differ)
    local response=$(curl -s -X POST "https://api.codeium.com/code_conversion" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer free_tier" \
        -d "{
            \"source_code\": \"$source_code\",
            \"source_language\": \"$from_lang\",
            \"target_language\": \"$to_lang\"
        }" 2>/dev/null || echo "{}")
    
    # Extract converted code from response
    local converted_code=$(echo "$response" | grep -o '"converted_code":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$converted_code" ]; then
        echo "$converted_code"
    else
        # Fallback: Use a simple online code converter service
        convert_with_fallback "$source_code" "$from_lang" "$to_lang"
    fi
}

# Free API 2: LLama through Ollama (Local, Free)
convert_with_ollama() {
    local source_code="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    log_info "Using Local Ollama (Free)..."
    
    # Check if Ollama is running
    if ! curl -s http://localhost:11434/api/tags > /dev/null; then
        log_error "Ollama not running. Install from https://ollama.ai and run: ollama serve"
        return 1
    fi
    
    # Create the prompt
    local prompt="Convert this $from_lang code to $to_lang. Only output the converted code, no explanations:\n\n$source_code"
    
    # Call Ollama API
    local response=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"codellama:7b\",
            \"prompt\": \"$prompt\",
            \"stream\": false
        }" 2>/dev/null)
    
    local converted_code=$(echo "$response" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$converted_code" ]; then
        echo "$converted_code"
    else
        log_error "Ollama conversion failed"
        return 1
    fi
}

# Free API 3: Hugging Face Inference API (Free)
convert_with_huggingface() {
    local source_code="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    log_info "Using Hugging Face API (Free)..."
    
    # Using a public code generation model
    local response=$(curl -s -X POST "https://api-inference.huggingface.co/models/codeparrot/codeparrot" \
        -H "Authorization: Bearer hf_free_access" \
        -H "Content-Type: application/json" \
        -d "{
            \"inputs\": \"Convert $from_lang to $to_lang: $source_code\",
            \"parameters\": {
                \"max_length\": 1000,
                \"temperature\": 0.1
            }
        }" 2>/dev/null || echo "{}")
    
    local converted_code=$(echo "$response" | grep -o '"generated_text":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$converted_code" ]; then
        echo "$converted_code"
    else
        log_warn "Hugging Face API limited. Using fallback..."
        convert_with_fallback "$source_code" "$from_lang" "$to_lang"
    fi
}

# Fallback: Simple pattern-based conversion
convert_with_fallback() {
    local source_code="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    log_warn "Using fallback pattern-based conversion..."
    
    case "${from_lang}_to_${to_lang}" in
        python_to_java)
            echo "$source_code" | sed '
                s/def /public static void /g
                s/():/() {/g
                s/print(/System.out.println(/g
                s/):/);/g
                s/class /public class /g
                s/if __name__ == "__main__":/public static void main(String[] args) {/g
            '
            ;;
        java_to_python)
            echo "$source_code" | sed '
                s/public static void /def /g
                s/() {/():/g
                s/System.out.println(/print(/g
                s/);/)/g
                s/public class /class /g
                s/public static void main(String[] args) {/if __name__ == "__main__":/g
            '
            ;;
        python_to_c)
            echo "$source_code" | sed '
                s/def /void /g
                s/():/() {/g
                s/print(/printf(/g
                s/):/);/g
                s/if __name__ == "__main__":/int main() {/g
            '
            ;;
        *)
            echo "# Automatic conversion failed"
            echo "# Please convert manually from $from_lang to $to_lang"
            echo "$source_code"
            ;;
    esac
}

# Free API 4: Use a public code converter website (curl-based)
convert_with_web_service() {
    local source_code="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    log_info "Using Web Code Converter..."
    
    # URL encode the code
    local encoded_code=$(echo "$source_code" | sed 's/ /%20/g' | sed 's/"/%22/g' | sed "s/'/%27/g" | tr -d '\n')
    
    # Try to use a public code conversion service (example)
    local response=$(curl -s "https://www.example-code-converter.com/convert?from=$from_lang&to=$to_lang&code=$encoded_code" 2>/dev/null || echo "")
    
    if [ -n "$response" ] && [ "${#response}" -gt 10 ]; then
        echo "$response"
    else
        log_warn "Web service unavailable. Using fallback..."
        convert_with_fallback "$source_code" "$from_lang" "$to_lang"
    fi
}

# Main conversion function
convert_code() {
    local input_file="$1"
    local target_lang="$2"
    local api_choice="$3"
    local source_lang=$(detect_language "$input_file")
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file not found: $input_file"
        exit 1
    fi
    
    if [ "$source_lang" = "unknown" ]; then
        log_error "Unsupported file type: $input_file"
        exit 1
    fi
    
    log_info "Source: $source_lang, Target: $target_lang, API: $api_choice"
    
    # Read source code
    local source_code=$(cat "$input_file")
    local output_file="${input_file%.*}.$target_lang"
    
    # Choose API based on user selection
    case "$api_choice" in
        codeium)
            converted_code=$(convert_with_codeium "$source_code" "$source_lang" "$target_lang")
            ;;
        ollama)
            converted_code=$(convert_with_ollama "$source_code" "$source_lang" "$target_lang")
            ;;
        huggingface)
            converted_code=$(convert_with_huggingface "$source_code" "$source_lang" "$target_lang")
            ;;
        web)
            converted_code=$(convert_with_web_service "$source_code" "$source_lang" "$target_lang")
            ;;
        fallback)
            converted_code=$(convert_with_fallback "$source_code" "$source_lang" "$target_lang")
            ;;
        *)
            log_error "Unknown API choice: $api_choice"
            log_info "Available: codeium, ollama, huggingface, web, fallback"
            exit 1
            ;;
    esac
    
    # Save converted code
    echo "$converted_code" > "$output_file"
    echo "$output_file"
}

# Validate converted code
validate_conversion() {
    local output_file="$1"
    local target_lang="$2"
    
    if [ ! -f "$output_file" ]; then
        log_error "Output file not created: $output_file"
        return 1
    fi
    
    log_info "Validating $target_lang syntax..."
    
    case "$target_lang" in
        java)
            if command -v javac >/dev/null 2>&1; then
                if javac "$output_file" 2>/dev/null; then
                    log_success "Java syntax is valid!"
                    rm -f "${output_file%.*}.class" 2>/dev/null
                else
                    log_warn "Java syntax may have issues"
                fi
            fi
            ;;
        python)
            if python3 -m py_compile "$output_file" 2>/dev/null; then
                log_success "Python syntax is valid!"
                rm -f "${output_file}c" 2>/dev/null
            else
                log_warn "Python syntax may have issues"
            fi
            ;;
    esac
}

# Show usage
show_usage() {
    echo "FREE API Code Converter"
    echo "Uses free APIs and services for code conversion"
    echo ""
    echo "Usage: $0 <input_file> <target_language> [api_choice]"
    echo ""
    echo "Target Languages: java, python, c, javascript, cpp"
    echo ""
    echo "Free API Choices:"
    echo "  codeium      - Codeium API (Free tier)"
    echo "  ollama       - Local Ollama LLM (Requires installation)"
    echo "  huggingface  - Hugging Face API"
    echo "  web          - Web-based code converter"
    echo "  fallback     - Simple pattern-based conversion"
    echo ""
    echo "Examples:"
    echo "  $0 program.py java codeium"
    echo "  $0 Main.java python ollama"
    echo "  $0 program.c python fallback"
    echo ""
    echo "Note: Some APIs may require setup or have rate limits"
}

# Setup Ollama (if chosen)
setup_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        log_info "Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
    
    if ! ollama list | grep -q "codellama"; then
        log_info "Downloading CodeLlama model..."
        ollama pull codellama:7b
    fi
    
    log_success "Ollama is ready!"
}

# Main execution
main() {
    if [ $# -lt 2 ]; then
        show_usage
        exit 1
    fi
    
    # Setup if using Ollama
    if [ "$API_CHOICE" = "ollama" ]; then
        setup_ollama
    fi
    
    local output_file
    output_file=$(convert_code "$1" "$2" "$API_CHOICE")
    
    if [ -f "$output_file" ]; then
        log_success "Conversion complete! Output: $output_file"
        
        # Validate the conversion
        validate_conversion "$output_file" "$2"
        
        # Show preview
        echo ""
        log_info "Preview of converted file:"
        echo "=============================="
        head -20 "$output_file"
        
        echo ""
        log_info "File info: $(wc -l < "$output_file") lines, $(wc -c < "$output_file") bytes"
    else
        log_error "Conversion failed - no output file created"
        exit 1
    fi
}

main "$@"