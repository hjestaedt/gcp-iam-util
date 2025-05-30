#!/usr/bin/env bash

subcmd_get_permissions() {
    local output_file=""
    local project_id=""
    local sources=()
    
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
            -h|--help) usage_get_permissions; return 0 ;;
            -*) usage_error "unknown option $1" usage_get_permissions ;;
            *) sources+=("$1"); shift ;;
        esac
    done
    
    # check that we have at least one source
    if [ ${#sources[@]} -eq 0 ]; then
        usage_error "at least one ROLE argument required" usage_get_permissions
    fi
    
    # validate output file and prerequisites
    if ! validate_output_file "$output_file"; then
        return 2
    fi
    
    if ! validate_prerequisites "${sources[@]}"; then
        return 2
    fi
    
    echo -e "${BLUE}getting permissions for ${#sources[@]} source(s)${NC}"
    echo -e "${BLUE}sources: $(IFS=', '; echo "${sources[*]}")${NC}"
    if [ -n "$output_file" ]; then
        echo -e "${BLUE}output file: $output_file${NC}"
    fi
    if [ -n "$project_id" ]; then
        echo -e "${BLUE}project ID: $project_id${NC}"
    fi
    echo -e "${BLUE}==============================================${NC}"
    
    # collect and deduplicate permissions
    local permissions_file
    if ! permissions_file=$(collect_permissions "$project_id" "${sources[@]}"); then
        return 2
    fi
    
    # output results
    if [ -n "$output_file" ]; then
        cp "$permissions_file" "$output_file"
        local perm_count
        perm_count=$(wc -l < "$output_file" | tr -d ' ')
        echo -e "${GREEN}✅ success: $perm_count permissions written to: $output_file${NC}"
    else
        echo -e "${BLUE}=== permissions list ===${NC}"
        cat "$permissions_file"
        echo ""
        local perm_count
        perm_count=$(wc -l < "$permissions_file" | tr -d ' ')
        echo -e "${GREEN}✅ success: listed $perm_count unique permissions${NC}"
    fi
    
    return 0
} 