#!/usr/bin/env bash

subcmd_is_subset() {
    local output_file=""
    local project_id=""
    local source=""
    local targets=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}error: output file not specified${NC}" >&2
                    return 2
                fi
                output_file="$2"; shift 2 ;;
            -p|--project)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}error: project ID not specified${NC}" >&2
                    return 2
                fi
                project_id="$2"; shift 2 ;;
            -h|--help) usage_is_subset; return 0 ;;
            -*) usage_error "unknown option $1" usage_is_subset ;;
            *)
                if [ -z "$source" ]; then
                    source="$1"
                else
                    targets+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # check that we have source and at least one target
    if [ -z "$source" ] || [ ${#targets[@]} -eq 0 ]; then
        usage_error "source and at least one target argument required" usage_is_subset
    fi
    
    # validate output file and prerequisites
    if ! validate_output_file "$output_file"; then
        return 2
    fi
    
    if ! validate_prerequisites "$source" "${targets[@]}"; then
        return 2
    fi
    
    echo -e "${BLUE}checking if all permissions of '$source' are included in ${#targets[@]} target(s)${NC}"
    echo -e "${BLUE}targets: $(IFS=', '; echo "${targets[*]}")${NC}"
    if [ -n "$output_file" ]; then
        echo -e "${BLUE}output file: $output_file${NC}"
        echo -e "${BLUE}missing permissions will be written to file (not displayed)${NC}"
    fi
    echo -e "${BLUE}==============================================${NC}"
    
    # get source permissions
    local source_perms
    source_perms=$(create_temp_file)
    if ! get_permissions "$source" "$source_perms" "$project_id"; then
        return 2
    fi
    
    # combine target permissions
    local target_perms
    if ! target_perms=$(combine_target_permissions "$project_id" "${targets[@]}"); then
        return 2
    fi
    
    # sort permissions for comparison
    local source_sorted
    source_sorted=$(create_temp_file)
    local target_sorted
    target_sorted=$(create_temp_file)
    sort "$source_perms" > "$source_sorted"
    sort "$target_perms" > "$target_sorted"
    
    # count permissions
    local source_count
    source_count=$(wc -l < "$source_sorted" | tr -d ' ')
    local target_count
    target_count=$(wc -l < "$target_sorted" | tr -d ' ')
    
    # determine source type for display
    local source_type="role"
    [ -f "$source" ] && source_type="file"
    
    echo ""
    echo -e "${BLUE}=== permission analysis ===${NC}"
    echo -e "source ($source_type: $source): ${YELLOW}$source_count${NC} permissions"
    echo -e "combined targets: ${YELLOW}$target_count${NC} unique permissions"
    echo ""
    
    # find permissions in source that are NOT in combined targets
    local missing_perms
    missing_perms=$(comm -23 "$source_sorted" "$target_sorted")
    
    if [ -z "$missing_perms" ]; then
        echo -e "${GREEN}✅ success: all permissions of '$source' are included in the combined targets${NC}"
        echo -e "${GREEN}   '$source' ⊆ {$(IFS=', '; echo "${targets[*]}")}${NC}"
        
        # Check if source and targets are identical
        local extra_perms
        extra_perms=$(comm -13 "$source_sorted" "$target_sorted")
        if [ -z "$extra_perms" ]; then
            echo -e "${BLUE}   source and combined targets have identical permissions${NC}"
        else
            local extra_count
            extra_count=$(echo "$extra_perms" | wc -l | tr -d ' ')
            echo -e "${BLUE}   combined targets have $extra_count additional permissions${NC}"
        fi
        
        # if output file specified but no missing permissions, create empty file
        if [ -n "$output_file" ]; then
            touch "$output_file"
            echo -e "${BLUE}   empty file created: $output_file${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}result: subset confirmed${NC}"
        return 0
    else
        local missing_count
        missing_count=$(echo "$missing_perms" | wc -l | tr -d ' ')
        echo -e "${RED}❌ failure: '$source' has $missing_count permissions NOT in combined targets${NC}"
        echo -e "${RED}   '$source' ⊄ {$(IFS=', '; echo "${targets[*]}")}${NC}"
        echo ""
        
        # Write missing permissions to file if specified
        if [ -n "$output_file" ]; then
            echo "$missing_perms" > "$output_file"
            echo -e "${YELLOW}📄 missing permissions written to: $output_file${NC}"
            echo -e "${BLUE}   total missing permissions: $missing_count${NC}"
        else
            echo -e "${RED}missing permissions (first 20):${NC}"
            local temp_missing
            temp_missing=$(create_temp_file)
            echo "$missing_perms" > "$temp_missing"
            head -20 "$temp_missing" | sed 's/^/  /'
            
            if [ "$missing_count" -gt 20 ]; then
                echo -e "  ${YELLOW}... and $((missing_count - 20)) more${NC}"
                echo -e "  ${BLUE}use -o option to save all missing permissions to a file${NC}"
            fi
        fi
        
        echo ""
        echo -e "${RED}result: not a subset${NC}"
        return 1
    fi
} 