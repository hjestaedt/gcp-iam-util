#!/usr/bin/env bash

get_permissions() {
    local source="$1"
    local output_file="$2"
    local project_id="$3"  
    
    if [ -f "$source" ]; then
        echo -e "${BLUE}reading permissions from file: $source${NC}" >&2
        
        local file_content
        file_content=$(cat "$source")
        
        if [[ "$file_content" == *";"* ]]; then
            echo -e "${BLUE}  detected semicolon-separated format${NC}" >&2
            echo "$file_content" | tr ';' '\n' | sed '/^$/d' > "$output_file"
        else
            echo -e "${BLUE}  detected line-separated format${NC}" >&2
            sed '/^$/d' "$source" > "$output_file"
        fi
        
        return 0
    else
        echo -e "${BLUE}getting permissions for role: $source${NC}" >&2
        
        local gcloud_cmd="gcloud iam roles describe \"$source\" --format=\"value(includedPermissions[])\""
        
        if [ -n "$project_id" ]; then
            gcloud_cmd="gcloud iam roles describe \"$source\" --project=\"$project_id\" --format=\"value(includedPermissions[])\""
        fi
        
        # get permissions as semicolon-separated string
        local perms_raw
        if ! perms_raw=$(eval "$gcloud_cmd" 2>/dev/null); then
            echo -e "${RED}error: unable to get permissions for role '$source'${NC}" >&2
            echo -e "${RED}possible causes:${NC}" >&2
            echo -e "${RED}  - role does not exist${NC}" >&2
            echo -e "${RED}  - file does not exist${NC}" >&2
            echo -e "${RED}  - insufficient permissions to view role${NC}" >&2
            echo -e "${RED}  - invalid role name format${NC}" >&2
            if [ -z "$project_id" ]; then
                echo -e "${RED}  - custom role needs project id (try -p option)${NC}" >&2
            else
                echo -e "${RED}  - wrong project id: $project_id${NC}" >&2
            fi
            return 1
        fi
        
        if [ -z "$perms_raw" ]; then
            echo -e "${YELLOW}warning: role '$source' has no permissions${NC}" >&2
            touch "$output_file"
            return 0
        fi
        
        echo "$perms_raw" | tr ';' '\n' | sed '/^$/d' > "$output_file"
        
        return 0
    fi
}

combine_target_permissions() {
    local project_id="$1"
    shift
    local targets=("$@")
    
    local combined_file
    combined_file=$(create_temp_file)
    local temp_counter=0
    local target_info=()
    
    echo -e "${BLUE}=== collecting target permissions ===${NC}" >&2
    
    touch "$combined_file"
    
    for target in "${targets[@]}"; do
        temp_counter=$((temp_counter + 1))
        local temp_target_file
        temp_target_file=$(create_temp_file)
        
        if ! get_permissions "$target" "$temp_target_file" "$project_id"; then
            return 1
        fi
        
        local target_count
        target_count=$(wc -l < "$temp_target_file" | tr -d ' ')
        local target_type="role"
        [ -f "$target" ] && target_type="file"
        
        target_info+=("$target_type: $target ($target_count permissions)")
        
        cat "$temp_target_file" >> "$combined_file"
    done
    
    sort "$combined_file" | uniq > "${combined_file}.sorted"
    mv "${combined_file}.sorted" "$combined_file"
    
    echo -e "${BLUE}target breakdown:${NC}" >&2
    for info in "${target_info[@]}"; do
        echo -e "  $info" >&2
    done
    
    local total_unique
    total_unique=$(wc -l < "$combined_file" | tr -d ' ')
    echo -e "${BLUE}combined unique permissions: ${YELLOW}$total_unique${NC}" >&2
    echo "" >&2
    
    echo "$combined_file"
    return 0
}

collect_permissions() {
    local project_id="$1"
    shift
    local sources=("$@")
    
    local combined_file
    combined_file=$(create_temp_file)
    local source_info=()
    
    echo -e "${BLUE}=== collecting permissions ===${NC}" >&2
    
    touch "$combined_file"
    
    for source in "${sources[@]}"; do
        local temp_source_file
        temp_source_file=$(create_temp_file)
        
        if ! get_permissions "$source" "$temp_source_file" "$project_id"; then
            return 1
        fi
        
        local source_count
        source_count=$(wc -l < "$temp_source_file" | tr -d ' ')
        local source_type="role"
        [ -f "$source" ] && source_type="file"
        
        source_info+=("$source_type: $source ($source_count permissions)")
        
        cat "$temp_source_file" >> "$combined_file"
    done
    
    sort "$combined_file" | uniq > "${combined_file}.sorted"
    mv "${combined_file}.sorted" "$combined_file"
    
    echo -e "${BLUE}source breakdown:${NC}" >&2
    for info in "${source_info[@]}"; do
        echo -e "  $info" >&2
    done
    
    local total_unique
    total_unique=$(wc -l < "$combined_file" | tr -d ' ')
    echo -e "${BLUE}total unique permissions: ${YELLOW}$total_unique${NC}" >&2
    echo "" >&2
    
    echo "$combined_file"
    return 0
} 