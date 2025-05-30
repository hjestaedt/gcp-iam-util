#!/usr/bin/env bash

validate_prerequisites() {
    local need_gcloud=false
    
    for arg in "$@"; do
        if [ ! -f "$arg" ]; then
            need_gcloud=true
            break
        fi
    done
    
    if [ "$need_gcloud" = true ]; then
        if ! command -v gcloud >/dev/null 2>&1; then
            echo -e "${RED}error: gcloud CLI is not installed or not in PATH${NC}" >&2
            return 2
        fi
        
        if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 >/dev/null 2>&1; then
            echo -e "${RED}error: no active gcloud authentication found${NC}" >&2
            return 1
        fi
    fi
    
    return 0
}

validate_output_file() {
    local output_file="$1"
    
    if [ -z "$output_file" ]; then
        return 0
    fi
    
    local output_dir
    output_dir=$(dirname "$output_file")
    if [ ! -d "$output_dir" ]; then
        echo -e "${RED}error: directory '$output_dir' does not exist${NC}" >&2
        return 2
    fi
    
    if [ -e "$output_file" ] && [ ! -w "$output_file" ]; then
        echo -e "${RED}error: file '$output_file' is not writable${NC}" >&2
        return 2
    fi
    
    return 0
} 