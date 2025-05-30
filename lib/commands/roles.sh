#!/usr/bin/env bash

cmd_roles() {
    if [ $# -eq 0 ]; then
        usage_error "no sub-command specified" usage_roles 2
    fi
    
    local sub_command=""
    
    case $1 in
        -h|--help) usage_roles; exit 0 ;;
        is-subset|get-permissions) sub_command="$1"; shift ;;
        *) echo "" >&2; usage_roles >&2; exit_error "Unknown roles sub-command '$1'" ;;
    esac
    
    case $sub_command in
        is-subset) subcmd_is_subset "$@"; exit $? ;;
        get-permissions) subcmd_get_permissions "$@"; exit $? ;;
    esac
} 