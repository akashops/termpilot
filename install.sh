#!/usr/bin/env bash
# ==============================================================================
# TermPilot Universal Multi-Shell & Cross-Distro Installer (install.sh)
# Compatible with Ubuntu, Debian, Kali, Arch, CentOS, Fedora, Alpine, macOS, WSL
# Shells Supported: Bash (3.2+), Zsh (5.0+), Fish (3.0+)
# ==============================================================================

set -e

REPO_URL="https://github.com/akashops/termpilot"
TARGET_DIR="${HOME}/.termpilot"

if [[ -n "${BASH_SOURCE[0]}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    TEMP_CLONE=$(mktemp -d 2>/dev/null || echo "/tmp/termpilot_install_$$")
    echo "Downloading TermPilot..."
    git clone --depth=1 "$REPO_URL" "$TEMP_CLONE" &>/dev/null || {
        echo "Error: Git required for remote installation. Clone manually."
        exit 1
    }
    SOURCE_DIR="$TEMP_CLONE"
fi

# ANSI Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[38;5;46m"
C_CYAN="\033[38;5;51m"
C_YELLOW="\033[38;5;220m"
C_BLUE="\033[38;5;39m"
C_PURPLE="\033[38;5;171m"

clear 2>/dev/null || true

echo -e "${C_CYAN}${C_BOLD}"
cat << 'EOF'
  _____                 ____  _ _       _   
 |_   _|__ _ __ _ __ __|  _ \(_) | ___ | |_ 
   | |/ _ \ '__| '_ ` _ \ |_) | | |/ _ \| __|
   | |  __/ |  | | | | | |  __/| | | (_) | |_ 
   |_|\___|_|  |_| |_| |_|_|   |_|_|\___/ \__|
   ⚡ Universal Open-Source Terminal Copilot ⚡
EOF
echo -e "${C_RESET}"
echo -e "${C_PURPLE}----------------------------------------------------------------------${C_RESET}"
echo -e "🚀 Deploying TermPilot on: ${C_CYAN}$(uname -s)${C_RESET} (${C_CYAN}$(uname -m)${C_RESET})"
echo -e "${C_PURPLE}----------------------------------------------------------------------${C_RESET}\n"

# 1. Directory Structure
echo -e "${C_BLUE}➜ [1/4] Initializing TermPilot directory at:${C_RESET} ${C_YELLOW}${TARGET_DIR}${C_RESET}"
mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/core" "${TARGET_DIR}/config" "${TARGET_DIR}/cache" "${TARGET_DIR}/assets"

# 2. Deploy Core Modules
echo -e "${C_BLUE}➜ [2/4] Deploying core modules & cheatsheet database...${C_RESET}"
cp -r "${SOURCE_DIR}/bin/"* "${TARGET_DIR}/bin/"
cp -r "${SOURCE_DIR}/core/"* "${TARGET_DIR}/core/"
cp -r "${SOURCE_DIR}/termpilot.plugin.sh" "${TARGET_DIR}/"
cp -r "${SOURCE_DIR}/uninstall.sh" "${TARGET_DIR}/"

if [[ -d "${SOURCE_DIR}/assets" ]]; then
    cp -r "${SOURCE_DIR}/assets/"* "${TARGET_DIR}/assets/" 2>/dev/null || true
fi

# Deploy default config
if [[ ! -f "${TARGET_DIR}/config/termpilot.conf" ]]; then
    cp "${SOURCE_DIR}/config/termpilot.conf" "${TARGET_DIR}/config/" 2>/dev/null || true
fi

# Set executable permissions
chmod +x "${TARGET_DIR}/bin/termpilot-helper.sh"
chmod +x "${TARGET_DIR}/termpilot.plugin.sh"
chmod +x "${TARGET_DIR}/uninstall.sh"
chmod +x "${TARGET_DIR}/core/"*.sh "${TARGET_DIR}/core/"*.bash "${TARGET_DIR}/core/"*.zsh 2>/dev/null || true

# 3. Build Binary Cache
echo -e "${C_BLUE}➜ [3/4] Building indexed binary cache for 0ms lookup...${C_RESET}"
bash "${TARGET_DIR}/bin/termpilot-helper.sh" doctor &>/dev/null || true

# 4. Multi-Shell Hooking
echo -e "${C_BLUE}➜ [4/4] Auto-configuring shells (Bash, Zsh, Fish)...${C_RESET}"

HOOK_SH="
# --- TermPilot Plugin Loader ---
export TERMPILOT_DIR=\"\$HOME/.termpilot\"
[ -f \"\$TERMPILOT_DIR/termpilot.plugin.sh\" ] && source \"\$TERMPILOT_DIR/termpilot.plugin.sh\"
# ------------------------------
"

# Bash Hook
for rc in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [[ -f "$rc" ]] || [[ "$rc" == "$HOME/.bashrc" ]]; then
        touch "$rc"
        if ! grep -q "termpilot.plugin.sh" "$rc"; then
            echo "$HOOK_SH" >> "$rc"
            echo -e "  ${C_GREEN}✔ Hooked into Bash (${rc})${C_RESET}"
        fi
    fi
done

# Zsh Hook
if command -v zsh &>/dev/null || [[ -f "$HOME/.zshrc" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    touch "$HOME/.zshrc"
    if ! grep -q "termpilot.plugin.sh" "$HOME/.zshrc"; then
        echo "$HOOK_SH" >> "$HOME/.zshrc"
        echo -e "  ${C_GREEN}✔ Hooked into Zsh (~/.zshrc)${C_RESET}"
    fi
fi

# Fish Hook
if command -v fish &>/dev/null || [[ -d "$HOME/.config/fish" ]]; then
    mkdir -p "$HOME/.config/fish"
    FISH_RC="$HOME/.config/fish/config.fish"
    touch "$FISH_RC"
    if ! grep -q "autosuggest.fish" "$FISH_RC"; then
        echo -e "\n# TermPilot Fish Loader\ntest -f \$HOME/.termpilot/core/autosuggest.fish; and source \$HOME/.termpilot/core/autosuggest.fish" >> "$FISH_RC"
        echo -e "  ${C_GREEN}✔ Hooked into Fish (~/.config/fish/config.fish)${C_RESET}"
    fi
fi

if [[ -n "$TEMP_CLONE" && -d "$TEMP_CLONE" ]]; then
    rm -rf "$TEMP_CLONE" 2>/dev/null || true
fi

echo -e "\n${C_PURPLE}----------------------------------------------------------------------${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}🎉 TermPilot Successfully Installed!${C_RESET}"
echo -e "${C_PURPLE}----------------------------------------------------------------------${C_RESET}\n"

echo -e "${C_BOLD}To activate immediately, run:${C_RESET}"
if [[ "$SHELL" == *"zsh"* ]]; then
    echo -e "  ${C_CYAN}source ~/.zshrc${C_RESET}"
elif [[ "$SHELL" == *"fish"* ]]; then
    echo -e "  ${C_CYAN}source ~/.config/fish/config.fish${C_RESET}"
else
    echo -e "  ${C_CYAN}source ~/.bashrc${C_RESET}"
fi

echo -e "\n${C_BOLD}🌟 Quick Test Commands:${C_RESET}"
echo -e "  • Diagnostics:     ${C_CYAN}termpilot doctor${C_RESET}"
echo -e "  • Cheatsheet:      ${C_CYAN}? docker${C_RESET} or ${C_CYAN}? iptables${C_RESET}"
echo -e "  • Add Custom Tool: ${C_CYAN}termpilot add \"mycmd|Dev|Deploy tool|mycmd --run\"${C_RESET}"
echo -e "  • 1-Key Auto-Fix:  Type ${C_YELLOW}sl${C_RESET} and press ${C_GREEN}1${C_RESET} to run ${C_GREEN}ls${C_RESET}!\n"
