# ==============================================================================
# TermPilot Fish Shell Integration (core/autosuggest.fish)
# ==============================================================================

set -q TERMPILOT_DIR; or set -gx TERMPILOT_DIR "$HOME/.termpilot"

function \?
    if test (count $argv) -eq 0
        echo "Usage: ? <command>  (e.g., ? tar, ? nmap, ? docker)"
        return 0
    end
    bash "$TERMPILOT_DIR/bin/termpilot-helper.sh" info $argv[1]
end

function termpilot
    bash "$TERMPILOT_DIR/bin/termpilot-helper.sh" $argv
end

function fish_command_not_found
    bash "$TERMPILOT_DIR/bin/termpilot-helper.sh" suggest $argv
end
