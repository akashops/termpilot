#!/usr/bin/env bash
# ==============================================================================
# SmartShell Universal Compatibility & Terminal Adapter (core/universal_compat.sh)
# Auto-detects terminal capabilities, color support, shell version & environment
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Terminal Color & Capability Detection
# ------------------------------------------------------------------------------
detect_terminal_capabilities() {
    # Check if connected to an interactive TTY
    if [[ ! -t 1 ]]; then
        export SMARTSH_NO_COLOR=true
    fi

    # Detect TrueColor / 24-bit support
    if [[ "$COLORTERM" == "truecolor" || "$COLORTERM" == "24bit" ]]; then
        export SMARTSH_COLOR_MODE="truecolor"
    # Detect 256 color support
    elif [[ "$TERM" =~ 256color || "$TERM" == "xterm-kitty" || "$TERM" == "alacritty" ]]; then
        export SMARTSH_COLOR_MODE="256color"
    # Fallback to standard 16 colors (Raw TTY / PuTTY / Serial)
    elif [[ "$TERM" =~ (xterm|screen|tmux|rxvt|vt100|linux) ]]; then
        export SMARTSH_COLOR_MODE="16color"
    else
        export SMARTSH_COLOR_MODE="basic"
    fi
}

detect_terminal_capabilities

# ------------------------------------------------------------------------------
# 2. Dynamic Adaptive Color Palette
# ------------------------------------------------------------------------------
if [[ "$SMARTSH_NO_COLOR" == "true" ]]; then
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_MAGENTA=""
    C_CYAN=""
    C_GREY=""
    C_ORANGE=""
else
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"

    if [[ "$SMARTSH_COLOR_MODE" == "256color" || "$SMARTSH_COLOR_MODE" == "truecolor" ]]; then
        C_RED="\033[38;5;196m"
        C_GREEN="\033[38;5;46m"
        C_YELLOW="\033[38;5;220m"
        C_BLUE="\033[38;5;39m"
        C_MAGENTA="\033[38;5;201m"
        C_CYAN="\033[38;5;51m"
        C_GREY="\033[38;5;242m"
        C_ORANGE="\033[38;5;208m"
    else
        # Standard 16-color ANSI fallbacks for legacy/lightweight terminals
        C_RED="\033[31m"
        C_GREEN="\033[32m"
        C_YELLOW="\033[33m"
        C_BLUE="\033[34m"
        C_MAGENTA="\033[35m"
        C_CYAN="\033[36m"
        C_GREY="\033[90m"
        C_ORANGE="\033[33m"
    fi
fi

export C_RESET C_BOLD C_DIM C_RED C_GREEN C_YELLOW C_BLUE C_MAGENTA C_CYAN C_GREY C_ORANGE
