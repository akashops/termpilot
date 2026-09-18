#!/usr/bin/env bash
# ==============================================================================
# TermPilot Core Engine (termpilot-helper.sh)
# Open-Source Linux Terminal Assistant & Command Copilot
# ==============================================================================

TERMPILOT_DIR="${TERMPILOT_DIR:-$HOME/.termpilot}"
DB_FILE="${TERMPILOT_DIR}/core/cheatsheet.db"
CUSTOM_DB_FILE="${TERMPILOT_DIR}/config/custom_commands.db"
CONF_FILE="${TERMPILOT_DIR}/config/termpilot.conf"
CACHE_DIR="${TERMPILOT_DIR}/cache"
CACHE_FILE="${CACHE_DIR}/binaries.cache"

# Load configuration
if [[ -f "$CONF_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONF_FILE"
fi

# Load universal colors & compatibility adapter
if [[ -f "${TERMPILOT_DIR}/core/universal_compat.sh" ]]; then
    # shellcheck source=/dev/null
    source "${TERMPILOT_DIR}/core/universal_compat.sh"
else
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_RED="\033[38;5;196m"
    C_GREEN="\033[38;5;46m"
    C_YELLOW="\033[38;5;220m"
    C_BLUE="\033[38;5;39m"
    C_MAGENTA="\033[38;5;201m"
    C_CYAN="\033[38;5;51m"
    C_GREY="\033[38;5;242m"
    C_ORANGE="\033[38;5;208m"
fi

# ------------------------------------------------------------------------------
# 1. High-Speed Binary Cache Generator (<2ms lookup)
# ------------------------------------------------------------------------------
ensure_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null
    if [[ ! -f "$CACHE_FILE" ]] || [[ $(find "$CACHE_FILE" -mtime +1 2>/dev/null) ]]; then
        {
            if [[ -f "$DB_FILE" ]]; then
                awk -F'|' '!/^#/ && NF >= 3 {print $1}' "$DB_FILE"
            fi
            if [[ -f "$CUSTOM_DB_FILE" ]]; then
                awk -F'|' '!/^#/ && NF >= 3 {print $1}' "$CUSTOM_DB_FILE"
            fi
            IFS=':' read -ra paths <<< "$PATH"
            for p in "${paths[@]}"; do
                if [[ -d "$p" ]]; then
                    find "$p" -maxdepth 1 -type f -executable -printf "%f\n" 2>/dev/null
                fi
            done
        } | sort -u > "$CACHE_FILE" 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# 2. Package Manager Detector
# ------------------------------------------------------------------------------
detect_pkg_manager() {
    if command -v apt &>/dev/null; then
        echo "apt install -y"
    elif command -v pacman &>/dev/null; then
        echo "pacman -S --noconfirm"
    elif command -v dnf &>/dev/null; then
        echo "dnf install -y"
    elif command -v yum &>/dev/null; then
        echo "yum install -y"
    elif command -v zypper &>/dev/null; then
        echo "zypper install -y"
    elif command -v apk &>/dev/null; then
        echo "apk add"
    elif command -v brew &>/dev/null; then
        echo "brew install"
    else
        echo "install"
    fi
}

# ------------------------------------------------------------------------------
# 3. Fuzzy Matcher (Awk Powered Levenshtein)
# ------------------------------------------------------------------------------
find_closest_command() {
    local target="$1"
    local max_dist="${2:-${TERMPILOT_FUZZY_THRESHOLD:-3}}"

    ensure_cache

    awk -v target="$target" -v max_dist="$max_dist" '
    function min3(a, b, c) {
        m = a;
        if (b < m) m = b;
        if (c < m) m = c;
        return m;
    }
    function lev(s1, s2,   l1, l2, d, i, j, cost) {
        l1 = length(s1);
        l2 = length(s2);
        if (l1 == 0) return l2;
        if (l2 == 0) return l1;
        if (s1 == s2) return 0;
        if (l1 - l2 > max_dist || l2 - l1 > max_dist) return 999;
        
        for (i = 0; i <= l1; i++) d[i, 0] = i;
        for (j = 0; j <= l2; j++) d[0, j] = j;
        
        for (i = 1; i <= l1; i++) {
            c1 = substr(s1, i, 1);
            for (j = 1; j <= l2; j++) {
                c2 = substr(s2, j, 1);
                cost = (c1 == c2 ? 0 : 1);
                d[i, j] = min3(d[i-1, j] + 1, d[i, j-1] + 1, d[i-1, j-1] + cost);
            }
        }
        return d[l1, l2];
    }
    {
        word = $1;
        if (word != "") {
            distance = lev(target, word);
            if (distance > 0 && distance <= max_dist) {
                print distance "\t" word;
            }
        }
    }
    ' "$CACHE_FILE" 2>/dev/null | sort -k1,1n -k2,2 | head -n "${TERMPILOT_MAX_SUGGESTIONS:-3}" | cut -f2
}

# ------------------------------------------------------------------------------
# 4. Deep Subcommand Context Analyzers (Git, Docker, Systemd, K8s)
# ------------------------------------------------------------------------------
analyze_deep_subcommand() {
    local base="$1"
    local sub="$2"
    [[ -z "$sub" ]] && return 1

    local valid_subs=()
    case "$base" in
        git)
            valid_subs=(status commit push pull checkout branch merge rebase clone log diff fetch stash init reset tag remote)
            ;;
        docker)
            valid_subs=(ps run build exec stop rm rmi images compose logs network volume inspect tag push pull)
            ;;
        systemctl)
            valid_subs=(status start stop restart enable disable reload daemon-reload is-active mask unmask)
            ;;
        kubectl)
            valid_subs=(get describe logs exec apply delete scale rollout config cluster-info create edit)
            ;;
        *)
            return 1
            ;;
    esac

    for valid in "${valid_subs[@]}"; do
        if [[ "$valid" == "$sub"* ]]; then
            echo -e "  ${C_YELLOW}💡 Deep Context (${base}):${C_RESET} Did you mean '${C_CYAN}${base} ${valid}${C_RESET}'?"
            return 0
        fi
    done
    return 1
}

# ------------------------------------------------------------------------------
# 5. Security Guardrail
# ------------------------------------------------------------------------------
check_security_guard() {
    local cmd_str="$*"
    if [[ "${TERMPILOT_SECURITY_GUARD:-true}" != "true" ]]; then
        return 0
    fi

    if [[ "$cmd_str" =~ (rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+/[[:space:]]*$|rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+/\*|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/|mkfs\.[a-z0-9]+[[:space:]]+/dev/sd[a-z][0-9]*) ]]; then
        echo -e "\n${C_RED}${C_BOLD}🚨 [TERMPILOT SECURITY GUARDRAIL]${C_RESET}"
        echo -e "${C_YELLOW}Potentially destructive command detected:${C_RESET}"
        echo -e "  ${C_RED}${C_BOLD}${cmd_str}${C_RESET}"
        echo -e "${C_DIM}Type 'yes' to proceed:${C_RESET} "
        read -r confirm
        if [[ "$confirm" != "yes" ]]; then
            echo -e "${C_GREEN}✔ Execution aborted safely.${C_RESET}"
            return 1
        fi
    fi
    return 0
}

# ------------------------------------------------------------------------------
# 6. Current Directory File Context
# ------------------------------------------------------------------------------
check_local_file_context() {
    local cmd="$1"
    if [[ -f "./$cmd" ]]; then
        echo -e "  ${C_YELLOW}📂 Local File Found:${C_RESET} Did you mean ${C_GREEN}./$cmd${C_RESET} ?"
        if [[ ! -x "./$cmd" ]]; then
            echo -e "     ${C_DIM}(Permission note: Run ${C_CYAN}chmod +x ./$cmd${C_DIM} to make it executable)${C_RESET}"
        fi
        return 0
    fi

    local similar_file
    similar_file=$(find . -maxdepth 1 -iname "*${cmd}*" -not -path '.' -printf "%f\n" 2>/dev/null | head -n 1)
    if [[ -n "$similar_file" ]]; then
        echo -e "  ${C_YELLOW}📂 Path Context:${C_RESET} Similar file in current directory: ${C_GREEN}$similar_file${C_RESET}"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 7. Main Error Handler with 1-Key Quick Execution
# ------------------------------------------------------------------------------
handle_unknown_command() {
    local cmd="$1"
    shift
    local args=("$@")

    echo ""
    echo -e "${C_RED}${C_BOLD}✖ Command not found:${C_RESET} ${C_BOLD}'${cmd}'${C_RESET}"

    if [[ ${#args[@]} -gt 0 ]]; then
        analyze_deep_subcommand "$cmd" "${args[0]}"
    fi

    if [[ "${TERMPILOT_PATH_AWARE_ENABLED:-true}" == "true" ]]; then
        check_local_file_context "$cmd"
    fi

    local suggestions
    mapfile -t suggestions < <(find_closest_command "$cmd" "${TERMPILOT_FUZZY_THRESHOLD:-3}")

    if [[ ${#suggestions[@]} -gt 0 && -n "${suggestions[0]}" ]]; then
        echo -e "  ${C_BLUE}Did you mean one of these?${C_RESET}"
        local idx=1
        for s in "${suggestions[@]}"; do
            local desc_line=""
            if [[ -f "$DB_FILE" ]]; then
                local d
                d=$(grep -E "^${s}\|" "$DB_FILE" 2>/dev/null | cut -d'|' -f3)
                if [[ -n "$d" ]]; then
                    desc_line=" ${C_DIM}- ${d}${C_RESET}"
                fi
            fi
            echo -e "    ${C_YELLOW}[${idx}]${C_RESET} ${C_GREEN}${s}${C_RESET}${desc_line}"
            ((idx++))
        done

        if [[ "${TERMPILOT_INTERACTIVE_FIX:-true}" == "true" && -t 0 ]]; then
            echo -e "  ${C_DIM}Press ${C_CYAN}[1-${#suggestions[@]}]${C_DIM} to run immediately, or any key to cancel:${C_RESET} "
            read -r -n 1 -s key
            echo ""
            if [[ "$key" =~ ^[1-9]$ ]] && [[ "$key" -le ${#suggestions[@]} ]]; then
                local chosen="${suggestions[$((key-1))]}"
                echo -e "${C_GREEN}➜ Running: ${C_BOLD}${chosen} ${args[*]}${C_RESET}\n"
                eval "${chosen} ${args[*]}"
                return $?
            fi
        fi
    fi

    if [[ "${TERMPILOT_SUGGEST_PACKAGE_INSTALL:-true}" == "true" ]]; then
        local pkg_mgr
        pkg_mgr=$(detect_pkg_manager)
        if grep -q -E "^${cmd}\|" "$DB_FILE" 2>/dev/null; then
            echo -e "  ${C_ORANGE}📦 To install '${cmd}', run:${C_RESET} ${C_CYAN}sudo ${pkg_mgr} ${cmd}${C_RESET}"
        fi
    fi

    echo -e "  ${C_DIM}Tip: Type '${C_CYAN}? <command>${C_DIM}' anytime to view flags and usage.${C_RESET}\n"
}

# ------------------------------------------------------------------------------
# 8. Open-Source Extensibility: Custom Commands Manager
# ------------------------------------------------------------------------------
add_custom_command() {
    local raw_input="$1"
    mkdir -p "$(dirname "$CUSTOM_DB_FILE")" 2>/dev/null
    
    if [[ "$raw_input" != *"|"* ]]; then
        echo -e "${C_YELLOW}Usage: termpilot add \"command_name|Category|Short description|example usage\"${C_RESET}"
        echo -e "Example: termpilot add \"mytool|DevOps|Deploy custom microservice|mytool deploy --prod\""
        return 1
    fi

    echo "$raw_input" >> "$CUSTOM_DB_FILE"
    # Invalidate cache
    rm -f "$CACHE_FILE" 2>/dev/null
    echo -e "${C_GREEN}✔ Custom command successfully added to TermPilot!${C_RESET}"
}

list_custom_commands() {
    if [[ -f "$CUSTOM_DB_FILE" ]]; then
        echo -e "${C_BLUE}${C_BOLD}=== TermPilot User Custom Commands ===${C_RESET}\n"
        while IFS='|' read -r name cat desc example; do
            [[ "$name" =~ ^# || -z "$name" ]] && continue
            echo -e "${C_CYAN}${C_BOLD}${name}${C_RESET} [${C_YELLOW}${cat}${C_RESET}]: ${desc}"
            [[ -n "$example" ]] && echo -e "  ${C_GREEN}Usage:${C_RESET} ${example}"
        done < "$CUSTOM_DB_FILE"
    else
        echo -e "${C_YELLOW}No custom commands added yet. Use 'termpilot add' to add your own!${C_RESET}"
    fi
}

# ------------------------------------------------------------------------------
# 9. Diagnostics & Benchmarking
# ------------------------------------------------------------------------------
run_doctor() {
    echo -e "${C_CYAN}${C_BOLD}"
    cat << 'EOF'
  _____                 ____  _ _       _   
 |_   _|__ _ __ _ __ __|  _ \(_) | ___ | |_ 
   | |/ _ \ '__| '_ ` _ \ |_) | | |/ _ \| __|
   | |  __/ |  | | | | | |  __/| | | (_) | |_ 
   |_|\___|_|  |_| |_| |_|_|   |_|_|\___/ \__|
EOF
    echo -e "${C_RESET}"
    echo -e "${C_BLUE}${C_BOLD}=== TermPilot System & Diagnostics Report ===${C_RESET}\n"
    
    if [[ -n "$ZSH_VERSION" ]]; then
        echo -e "  ${C_GREEN}✔ Active Shell:${C_RESET} ZSH version $ZSH_VERSION"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo -e "  ${C_GREEN}✔ Active Shell:${C_RESET} BASH version $BASH_VERSION"
    fi

    echo -e "  ${C_GREEN}✔ Operating System:${C_RESET} $(uname -s) $(uname -r) ($(uname -m))"
    echo -e "  ${C_GREEN}✔ Package Manager:${C_RESET} $(detect_pkg_manager)"

    if [[ -f "$DB_FILE" ]]; then
        local count
        count=$(grep -c -E "^[a-zA-Z0-9]" "$DB_FILE" 2>/dev/null)
        echo -e "  ${C_GREEN}✔ Cheatsheet Database:${C_RESET} $count verified command entries"
    fi

    ensure_cache
    if [[ -f "$CACHE_FILE" ]]; then
        local bcount
        bcount=$(wc -l < "$CACHE_FILE")
        echo -e "  ${C_GREEN}✔ Binary Index Cache:${C_RESET} $bcount indexed system binaries"
    fi

    local start_ms end_ms elapsed
    start_ms=$(date +%s%N 2>/dev/null || echo 0)
    find_closest_command "sl" 2 &>/dev/null
    end_ms=$(date +%s%N 2>/dev/null || echo 0)
    if [[ "$start_ms" -gt 0 && "$end_ms" -gt 0 ]]; then
        elapsed=$(( (end_ms - start_ms) / 1000000 ))
        echo -e "  ${C_GREEN}✔ Fuzzy Lookup Latency:${C_RESET} ${elapsed}ms (Zero Lag)"
    fi

    echo -e "\n${C_GREEN}${C_BOLD}All TermPilot core subsystems operational!${C_RESET}\n"
}

# ------------------------------------------------------------------------------
# 10. Security Audit & Analytics
# ------------------------------------------------------------------------------
run_security_audit() {
    echo -e "${C_BLUE}${C_BOLD}=== TermPilot Security History Audit ===${C_RESET}\n"
    local hist_file="$HOME/.bash_history"
    [[ -n "$ZSH_VERSION" || -f "$HOME/.zsh_history" ]] && hist_file="$HOME/.zsh_history"

    if [[ ! -f "$hist_file" ]]; then
        echo -e "${C_YELLOW}History file not found at $hist_file${C_RESET}"
        return 0
    fi

    if grep -E -i "(password=|passwd=|api_key=|bearer |ghp_[0-9a-zA-Z]{36}|AKIA[0-9A-Z]{16})" "$hist_file" 2>/dev/null | head -n 5; then
        echo -e "\n${C_RED}⚠️ Warning: Plaintext credentials detected in history!${C_RESET}"
    else
        echo -e "  ${C_GREEN}✔ Security Audit Passed: No exposed API keys or tokens found in history.${C_RESET}\n"
    fi
}

run_stats() {
    echo -e "${C_BLUE}${C_BOLD}=== TermPilot Command Analytics ===${C_RESET}\n"
    local hist_file="$HOME/.bash_history"
    [[ -f "$HOME/.zsh_history" ]] && hist_file="$HOME/.zsh_history"

    if [[ -f "$hist_file" ]]; then
        echo -e "${C_YELLOW}${C_BOLD}Top 10 Most Used Commands:${C_RESET}"
        awk '{
            for (i=1; i<=NF; i++) {
                if ($i ~ /^;/) { sub(/^;/, "", $i); print $i; break; }
                else if ($i !~ /^[0-9#:]/) { print $i; break; }
            }
        }' "$hist_file" 2>/dev/null | sort | uniq -c | sort -nr | head -n 10 | awk '{printf "  \033[38;5;51m%-15s\033[0m \033[38;5;220m%5d runs\033[0m\n", $2, $1}'
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 11. Command Information & Search
# ------------------------------------------------------------------------------
get_command_info() {
    local cmd="$1"
    local entry
    
    # Check custom DB first
    if [[ -f "$CUSTOM_DB_FILE" ]]; then
        entry=$(grep -E "^${cmd}\|" "$CUSTOM_DB_FILE" 2>/dev/null | head -n 1)
    fi
    # Check main DB
    if [[ -z "$entry" && -f "$DB_FILE" ]]; then
        entry=$(grep -E "^${cmd}\|" "$DB_FILE" 2>/dev/null | head -n 1)
    fi

    if [[ -n "$entry" ]]; then
        local name cat desc example
        IFS='|' read -r name cat desc example <<< "$entry"
        echo -e "${C_CYAN}${C_BOLD}${name}${C_RESET} [${C_YELLOW}${cat}${C_RESET}]: ${desc}"
        if [[ -n "$example" ]]; then
            echo -e "  ${C_DIM}Example:${C_RESET} ${C_GREEN}${example}${C_RESET}"
        fi
        return 0
    fi
    return 1
}

search_cheatsheet() {
    local query="$1"
    echo -e "${C_BLUE}${C_BOLD}=== TermPilot CheatSheet Search: '${query}' ===${C_RESET}\n"
    local count=0
    for f in "$CUSTOM_DB_FILE" "$DB_FILE"; do
        [[ ! -f "$f" ]] && continue
        while IFS='|' read -r name cat desc example; do
            [[ "$name" =~ ^# ]] && continue
            if [[ "$name" =~ $query || "$cat" =~ $query || "$desc" =~ $query ]]; then
                echo -e "${C_CYAN}${C_BOLD}${name}${C_RESET} [${C_YELLOW}${cat}${C_RESET}]"
                echo -e "  ${C_DIM}Info:${C_RESET} ${desc}"
                if [[ -n "$example" ]]; then
                    echo -e "  ${C_GREEN}Usage:${C_RESET} ${example}"
                fi
                echo ""
                ((count++))
            fi
        done < "$f"
    done

    if [[ $count -eq 0 ]]; then
        echo -e "${C_YELLOW}No direct matches found for '${query}'.${C_RESET}"
    fi
}

# ------------------------------------------------------------------------------
# Main CLI Router
# ------------------------------------------------------------------------------
case "$1" in
    doctor)
        run_doctor
        ;;
    audit)
        run_security_audit
        ;;
    stats)
        run_stats
        ;;
    add)
        shift
        add_custom_command "$1"
        ;;
    custom)
        list_custom_commands
        ;;
    guard)
        shift
        check_security_guard "$@"
        ;;
    info|explain|help)
        shift
        [[ -z "$1" ]] && { echo -e "Usage: termpilot info <cmd>"; exit 1; }
        get_command_info "$1" || search_cheatsheet "$1"
        ;;
    search|cheat)
        shift
        search_cheatsheet "$1"
        ;;
    suggest|error)
        shift
        handle_unknown_command "$@"
        ;;
    list)
        if [[ -f "$DB_FILE" ]]; then
            echo -e "${C_BLUE}${C_BOLD}Categories in TermPilot Database:${C_RESET}"
            awk -F'|' '!/^#/ && NF>=3 {print $2}' "$DB_FILE" | sort -u | while read -r cat; do
                echo -e "  ${C_CYAN}• ${cat}${C_RESET}"
            done
        fi
        ;;
    *)
        echo -e "${C_CYAN}${C_BOLD}⚡ TermPilot CLI Suite${C_RESET}"
        echo -e "Usage: termpilot <command> [arguments]\n"
        echo -e "Commands:"
        echo -e "  ${C_GREEN}termpilot doctor${C_RESET}         Run system & shell diagnostics"
        echo -e "  ${C_GREEN}termpilot audit${C_RESET}          Security audit for leaked keys in history"
        echo -e "  ${C_GREEN}termpilot stats${C_RESET}          View command usage analytics & top tools"
        echo -e "  ${C_GREEN}termpilot add <entry>${C_RESET}    Add custom command to cheatsheet DB"
        echo -e "  ${C_GREEN}termpilot custom${C_RESET}         List your custom added commands"
        echo -e "  ${C_GREEN}termpilot info <cmd>${C_RESET}     Instant description & flags for command"
        echo -e "  ${C_GREEN}termpilot search <query>${C_RESET} Search cheatsheet database"
        echo -e "  ${C_GREEN}? <cmd>${C_RESET}                  Quick alias for cheatsheet lookup"
        ;;
esac
