#!/usr/bin/env bash
# ==============================================================================
# TermPilot Bash Auto-Suggestion Engine (core/autosuggest.bash)
# ==============================================================================

TERMPILOT_DIR="${TERMPILOT_DIR:-$HOME/.termpilot}"
DB_FILE="${TERMPILOT_DIR}/core/cheatsheet.db"
CUSTOM_DB_FILE="${TERMPILOT_DIR}/config/custom_commands.db"

# Enable modern Bash completion settings
shopt -s autocd 2>/dev/null
shopt -s dirspell 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s checkwinsize 2>/dev/null
shopt -s cmdhist 2>/dev/null

# Readline configurations
bind 'set completion-ignore-case on' 2>/dev/null
bind 'set show-all-if-ambiguous on' 2>/dev/null
bind 'set colored-stats on' 2>/dev/null
bind 'set colored-completion-prefix on' 2>/dev/null
bind 'set menu-complete-display-prefix on' 2>/dev/null

# Up/Down arrow smart history search based on first typed characters
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

# Tab smart cycling
bind 'TAB: menu-complete' 2>/dev/null
bind '"\e[Z": menu-complete-backward' 2>/dev/null

# Smart custom completer
_termpilot_complete() {
    local cur prev
    _init_completion -n : 2>/dev/null || {
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
    }

    if [[ $COMP_CWORD -eq 0 || ($COMP_CWORD -eq 1 && -z "$prev") ]]; then
        local db_matches=""
        if [[ -f "$DB_FILE" ]]; then
            db_matches=$(awk -F'|' -v cur="$cur" '!/^#/ && $1 ~ "^"cur {print $1}' "$DB_FILE" 2>/dev/null)
        fi
        if [[ -f "$CUSTOM_DB_FILE" ]]; then
            local custom_matches
            custom_matches=$(awk -F'|' -v cur="$cur" '!/^#/ && $1 ~ "^"cur {print $1}' "$CUSTOM_DB_FILE" 2>/dev/null)
            db_matches="$db_matches $custom_matches"
        fi
        # shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "$db_matches" -- "$cur"))
        return 0
    fi

    local base_cmd="${COMP_WORDS[0]}"
    if [[ -f "$DB_FILE" && "$cur" == -* ]]; then
        local example
        example=$(grep -E "^${base_cmd}\|" "$DB_FILE" 2>/dev/null | cut -d'|' -f4)
        if [[ -n "$example" ]]; then
            local flags
            flags=$(echo "$example" | grep -o -E -- '-[a-zA-Z0-9-]+' | sort -u)
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "$flags" -- "$cur"))
            return 0
        fi
    fi

    # Fallback to standard filename completion
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -f -- "$cur"))
}

complete -D -F _termpilot_complete 2>/dev/null || true
