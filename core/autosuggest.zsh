#!/usr/bin/env zsh
# ==============================================================================
# TermPilot ZSH Auto-Suggestion Ghost-Text Engine (core/autosuggest.zsh)
# ==============================================================================

TERMPILOT_DIR="${TERMPILOT_DIR:-$HOME/.termpilot}"
DB_FILE="${TERMPILOT_DIR}/core/cheatsheet.db"
CUSTOM_DB_FILE="${TERMPILOT_DIR}/config/custom_commands.db"

TERMPILOT_SUGGESTION_COLOR="${TERMPILOT_SUGGESTION_COLOR:-242}"
_TERMPILOT_SUGGESTION=""

_termpilot_fetch_suggestion() {
    local prefix="$1"
    [[ -z "$prefix" ]] && return 1

    # 1. Search recent command history
    local hist_match
    hist_match=$(fc -l -n -r 1 2>/dev/null | grep -E "^[ ]*${prefix}" | head -n 1 | sed -e 's/^[[:space:]]*//')
    if [[ -n "$hist_match" && "$hist_match" != "$prefix" ]]; then
        echo "$hist_match"
        return 0
    fi

    # 2. Search custom database & main cheatsheet DB
    for db in "$CUSTOM_DB_FILE" "$DB_FILE"; do
        if [[ -f "$db" ]]; then
            local db_example
            db_example=$(awk -F'|' -v p="$prefix" '!/^#/ && $1 ~ "^"p {print $4; exit}' "$db" 2>/dev/null)
            if [[ -n "$db_example" && "$db_example" != "$prefix" ]]; then
                echo "$db_example"
                return 0
            fi
        fi
    done

    return 1
}

_termpilot_zle_highlight() {
    local buf="$BUFFER"
    _TERMPILOT_SUGGESTION=""

    if [[ -n "$buf" && "$CURSOR" -eq "${#buf}" ]]; then
        local match
        match=$(_termpilot_fetch_suggestion "$buf")
        if [[ -n "$match" && "$match" == "${buf}"* ]]; then
            _TERMPILOT_SUGGESTION="${match#$buf}"
            POSTDISPLAY=$'\e[38;5;'"${TERMPILOT_SUGGESTION_COLOR}m${_TERMPILOT_SUGGESTION}"$'\e[0m'
            return
        fi
    fi
    POSTDISPLAY=""
}

_termpilot_accept_suggestion() {
    if [[ -n "$_TERMPILOT_SUGGESTION" && "$CURSOR" -eq "${#BUFFER}" ]]; then
        BUFFER="${BUFFER}${_TERMPILOT_SUGGESTION}"
        CURSOR="${#BUFFER}"
        _TERMPILOT_SUGGESTION=""
        POSTDISPLAY=""
        zle redisplay
    else
        zle forward-char
    fi
}

_termpilot_accept_eol() {
    if [[ -n "$_TERMPILOT_SUGGESTION" ]]; then
        BUFFER="${BUFFER}${_TERMPILOT_SUGGESTION}"
        CURSOR="${#BUFFER}"
        _TERMPILOT_SUGGESTION=""
        POSTDISPLAY=""
        zle redisplay
    else
        zle end-of-line
    fi
}

zle -N _termpilot_accept_suggestion
zle -N _termpilot_accept_eol

autoload -Uz add-zsh-hook 2>/dev/null

_termpilot_self_insert() {
    zle .self-insert
    _termpilot_zle_highlight
}
zle -N self-insert _termpilot_self_insert

_termpilot_backward_delete_char() {
    zle .backward-delete-char
    _termpilot_zle_highlight
}
zle -N backward-delete-char _termpilot_backward_delete_char

# Key bindings
bindkey '^[[C' _termpilot_accept_suggestion   # Right Arrow
bindkey '^F'   _termpilot_accept_suggestion   # Ctrl + F
bindkey '^E'   _termpilot_accept_eol          # Ctrl + E (End of line)
bindkey '^[[F' _termpilot_accept_eol          # End key

# History navigation
bindkey '^[[A' history-beginning-search-backward # Up Arrow
bindkey '^[[B' history-beginning-search-forward  # Down Arrow
