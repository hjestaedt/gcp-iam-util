#!/usr/bin/env bash
# Permission processing functions

# Function to get permissions from role or file
get_permissions() {
    local source="$1"
    local output_file="$2"
    local project_id="$3"  # Optional project ID for custom roles
    
    # Check if source is a file
    if [ -f "$source" ]; then
        echo -e "${BLUE}Reading permissions from file: $source${NC}" >&2
        
        # Read file and check if it's semicolon-separated or line-separated
        local file_content
        file_content=$(cat "$source")
        
        # If file contains semicolons, assume it's semicolon-separated
        if [[ "$file_content" == *";"* ]]; then
            echo -e "${BLUE}  Detected semicolon-separated format${NC}" >&2
            echo "$file_content" | tr ';' '\n' | sed '/^$/d' > "$output_file"
        else
            echo -e "${BLUE}  Detected line-separated format${NC}" >&2
            # Remove empty lines and copy to output
            sed '/^$/d' "$source" > "$output_file"
        fi
        
        return 0
    else
        # Treat as role name
        echo -e "${BLUE}Getting permissions for role: $source${NC}" >&2
        
        # Build gcloud command
        local gcloud_cmd="gcloud iam roles describe \"$source\" --format=\"value(includedPermissions[])\""
        
        # Add project flag if specified
        if [ -n "$project_id" ]; then
            gcloud_cmd="gcloud iam roles describe \"$source\" --project=\"$project_id\" --format=\"value(includedPermissions[])\""
        fi
        
        # Get permissions as semicolon-separated string
        local perms_raw
        if ! perms_raw=$(eval "$gcloud_cmd" 2>/dev/null); then
            echo -e "${RED}Error: Unable to get permissions for role '$source'${NC}" >&2
            echo -e "${RED}Possible causes:${NC}" >&2
            echo -e "${RED}  - Role does not exist${NC}" >&2
            echo -e "${RED}  - File does not exist${NC}" >&2
            echo -e "${RED}  - Insufficient permissions to view role${NC}" >&2
            echo -e "${RED}  - Invalid role name format${NC}" >&2
            if [ -z "$project_id" ]; then
                echo -e "${RED}  - Custom role needs project ID (try -p option)${NC}" >&2
            else
                echo -e "${RED}  - Wrong project ID: $project_id${NC}" >&2
            fi
            return 1
        fi
        
        # Check if role has any permissions
        if [ -z "$perms_raw" ]; then
            echo -e "${YELLOW}Warning: Role '$source' has no permissions${NC}" >&2
            touch "$output_file"  # Create empty file for comparison
            return 0
        fi
        
        # Convert semicolon-separated permissions to line-separated format
        echo "$perms_raw" | tr ';' '\n' | sed '/^$/d' > "$output_file"
        
        return 0
    fi
}

# Function to combine permissions from multiple targets (for check-subset)
combine_target_permissions() {
    local project_id="$1"  # First argument is project_id
    shift  # Remove project_id from arguments
    local targets=("$@")   # Rest are targets
    
    local combined_file
    combined_file=$(create_temp_file)
    local temp_counter=0
    local target_info=()
    
    echo -e "${BLUE}=== Collecting Target Permissions ===${NC}" >&2
    
    # Initialize combined file as empty
    touch "$combined_file"
    
    # Process each target
    for target in "${targets[@]}"; do
        temp_counter=$((temp_counter + 1))
        local temp_target_file
        temp_target_file=$(create_temp_file)
        
        if ! get_permissions "$target" "$temp_target_file" "$project_id"; then
            return 1
        fi
        
        # Count permissions for this target
        local target_count
        target_count=$(wc -l < "$temp_target_file" | tr -d ' ')
        local target_type="role"
        [ -f "$target" ] && target_type="file"
        
        target_info+=("$target_type: $target ($target_count permissions)")
        
        # Append to combined file
        cat "$temp_target_file" >> "$combined_file"
    done
    
    # Remove duplicates and sort
    sort "$combined_file" | uniq > "${combined_file}.sorted"
    mv "${combined_file}.sorted" "$combined_file"
    
    # Display target information
    echo -e "${BLUE}Target breakdown:${NC}" >&2
    for info in "${target_info[@]}"; do
        echo -e "  $info" >&2
    done
    
    local total_unique
    total_unique=$(wc -l < "$combined_file" | tr -d ' ')
    echo -e "${BLUE}Combined unique permissions: ${YELLOW}$total_unique${NC}" >&2
    echo "" >&2
    
    # Return the combined file path via stdout (caller should capture this)
    echo "$combined_file"
    return 0
}

# Function to collect and deduplicate permissions from multiple sources
collect_permissions() {
    local project_id="$1"  # First argument is project_id
    shift  # Remove project_id from arguments
    local sources=("$@")   # Rest are sources
    
    local combined_file
    combined_file=$(create_temp_file)
    local source_info=()
    
    echo -e "${BLUE}=== Collecting Permissions ===${NC}" >&2
    
    # Initialize combined file as empty
    touch "$combined_file"
    
    # Process each source
    for source in "${sources[@]}"; do
        local temp_source_file
        temp_source_file=$(create_temp_file)
        
        if ! get_permissions "$source" "$temp_source_file" "$project_id"; then
            return 1
        fi
        
        # Count permissions for this source
        local source_count
        source_count=$(wc -l < "$temp_source_file" | tr -d ' ')
        local source_type="role"
        [ -f "$source" ] && source_type="file"
        
        source_info+=("$source_type: $source ($source_count permissions)")
        
        # Append to combined file
        cat "$temp_source_file" >> "$combined_file"
    done
    
    # Remove duplicates and sort
    sort "$combined_file" | uniq > "${combined_file}.sorted"
    mv "${combined_file}.sorted" "$combined_file"
    
    # Display source information
    echo -e "${BLUE}Source breakdown:${NC}" >&2
    for info in "${source_info[@]}"; do
        echo -e "  $info" >&2
    done
    
    local total_unique
    total_unique=$(wc -l < "$combined_file" | tr -d ' ')
    echo -e "${BLUE}Total unique permissions: ${YELLOW}$total_unique${NC}" >&2
    echo "" >&2
    
    # Return the combined file path via stdout (caller should capture this)
    echo "$combined_file"
    return 0
} 