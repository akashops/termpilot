#!/usr/bin/env bash
# ==============================================================================
# TermPilot Main Plugin Entrypoint (termpilot.plugin.sh)
# Source this file inside ~/.bashrc, ~/.zshrc or your shell profile
# ==============================================================================

# Locate installation directory
if [[ -z "$TERMPILOT_DIR" ]]; then
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        TERMPILOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    elif [[ -n "${(%):-%N}" ]]; then
        TERMPILOT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
    else
        TERMPILOT_DIR="$HOME/.termpilot"
    fi
fi
export TERMPILOT_DIR

# 1. Universal Terminal & Color Compatibility Adapter
if [[ -f "${TERMPILOT_DIR}/core/universal_compat.sh" ]]; then
    # shellcheck source=/dev/null
    source "${TERMPILOT_DIR}/core/universal_compat.sh"
fi

# 2. Load User Configuration
if [[ -f "${TERMPILOT_DIR}/config/termpilot.conf" ]]; then
    # shellcheck source=/dev/null
    source "${TERMPILOT_DIR}/config/termpilot.conf"
fi

# 3. Add bin directory to PATH for 'termpilot' CLI
if [[ -d "${TERMPILOT_DIR}/bin" ]]; then
    if [[ ":$PATH:" != *":${TERMPILOT_DIR}/bin:"* ]]; then
        export PATH="${TERMPILOT_DIR}/bin:$PATH"
    fi
    chmod +x "${TERMPILOT_DIR}/bin/termpilot-helper.sh" 2>/dev/null
fi

# 4. Create 'termpilot' wrapper function
termpilot() {
    "${TERMPILOT_DIR}/bin/termpilot-helper.sh" "$@"
}

# 5. Load Error & Typo Handler Hook
if [[ "${TERMPILOT_ERROR_SUGGEST_ENABLED:-true}" == "true" ]]; then
    if [[ -f "${TERMPILOT_DIR}/core/error_handler.sh" ]]; then
        # shellcheck source=/dev/null
        source "${TERMPILOT_DIR}/core/error_handler.sh"
    fi
fi

# 6. Load Shell Specific Autosuggestion Engine
if [[ "${TERMPILOT_AUTOSUGGEST_ENABLED:-true}" == "true" ]]; then
    if [[ -n "$ZSH_VERSION" ]]; then
        if [[ -f "${TERMPILOT_DIR}/core/autosuggest.zsh" ]]; then
            # shellcheck source=/dev/null
            source "${TERMPILOT_DIR}/core/autosuggest.zsh"
        fi
    elif [[ -n "$BASH_VERSION" ]]; then
        if [[ -f "${TERMPILOT_DIR}/core/autosuggest.bash" ]]; then
            # shellcheck source=/dev/null
            source "${TERMPILOT_DIR}/core/autosuggest.bash"
        fi
    fi
fi
