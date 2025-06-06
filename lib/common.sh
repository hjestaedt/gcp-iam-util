#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

TEMP_FILES=()

version() {
    echo "$SCRIPT_NAME version $VERSION"
}

cleanup() {
    local exit_code=$?
    if [ ${#TEMP_FILES[@]} -gt 0 ]; then
        for temp_file in "${TEMP_FILES[@]}"; do
            rm -f "$temp_file" 2>/dev/null || true
        done
    fi
    exit $exit_code
}
trap cleanup EXIT

create_temp_file() {
    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")
    echo "$temp_file"
}

exit_error() {
    local message="$1"
    local exit_code="${2:-2}"
    
    echo -e "${RED}error: $message${NC}" >&2
    exit "$exit_code"
}

return_error() {
    local message="$1"
    local return_code="${2:-2}"
    
    echo -e "${RED}error: $message${NC}" >&2
    return "$return_code"
}

usage_error() {
    local message="$1"
    local usage_function="$2"
    local return_code="${3:-2}"
    
    $usage_function >&2
    echo "" >&2
    echo -e "${RED}error: $message${NC}" >&2

    return "$return_code"
} 