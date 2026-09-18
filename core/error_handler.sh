#!/usr/bin/env bash
# ==============================================================================
# TermPilot Error & Typo Handler Hook (core/error_handler.sh)
# ==============================================================================

TERMPILOT_DIR="${TERMPILOT_DIR:-$HOME/.termpilot}"
HELPER_BIN="${TERMPILOT_DIR}/bin/termpilot-helper.sh"

# 1. Hook for BASH: command_not_found_handle
if [[ -n "$BASH_VERSION" ]]; then
    command_not_found_handle() {
        if [[ -x "$HELPER_BIN" ]]; then
            "$HELPER_BIN" suggest "$@"
        elif [[ -f "$HELPER_BIN" ]]; then
            bash "$HELPER_BIN" suggest "$@"
        else
            echo "bash: $1: command not found"
        fi
        return 127
    }
fi

# 2. Hook for ZSH: command_not_found_handler
if [[ -n "$ZSH_VERSION" ]]; then
    command_not_found_handler() {
        if [[ -x "$HELPER_BIN" ]]; then
            "$HELPER_BIN" suggest "$@"
        elif [[ -f "$HELPER_BIN" ]]; then
            zsh "$HELPER_BIN" suggest "$@"
        else
            echo "zsh: command not found: $1"
        fi
        return 127
    }
fi

# 3. Quick '?' Helper Function
\?() {
    if [[ -z "$1" ]]; then
        echo -e "\033[38;5;220mUsage:\033[0m ? <command>  (e.g., ? tar, ? nmap, ? docker, ? git)"
        return 0
    fi
    if [[ -f "$HELPER_BIN" ]]; then
        bash "$HELPER_BIN" info "$1"
    fi
}
