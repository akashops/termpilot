#!/usr/bin/env bash
# ==============================================================================
# TermPilot Uninstaller (uninstall.sh)
# ==============================================================================

TARGET_DIR="${HOME}/.termpilot"

C_RESET="\033[0m"
C_GREEN="\033[38;5;46m"
C_YELLOW="\033[38;5;220m"

echo -e "${C_YELLOW}Removing TermPilot from your system...${C_RESET}"

# 1. Clean ~/.bashrc & ~/.bash_profile
for rc in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [[ -f "$rc" ]]; then
        sed -i '/# --- TermPilot Plugin Loader ---/,/# ------------------------------/d' "$rc" 2>/dev/null || true
        sed -i '/# --- SmartShell Plugin Loader ---/,/# -------------------------------/d' "$rc" 2>/dev/null || true
        echo -e "${C_GREEN}✔ Cleaned ${rc}${C_RESET}"
    fi
done

# 2. Clean ~/.zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '/# --- TermPilot Plugin Loader ---/,/# ------------------------------/d' "$HOME/.zshrc" 2>/dev/null || true
    sed -i '/# --- SmartShell Plugin Loader ---/,/# -------------------------------/d' "$HOME/.zshrc" 2>/dev/null || true
    echo -e "${C_GREEN}✔ Cleaned ~/.zshrc${C_RESET}"
fi

# 3. Clean Fish config
if [[ -f "$HOME/.config/fish/config.fish" ]]; then
    sed -i '/# TermPilot Fish Loader/,/autosuggest.fish/d' "$HOME/.config/fish/config.fish" 2>/dev/null || true
    echo -e "${C_GREEN}✔ Cleaned Fish (~/.config/fish/config.fish)${C_RESET}"
fi

# 4. Remove target directory
if [[ -d "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"
    echo -e "${C_GREEN}✔ Removed ${TARGET_DIR}${C_RESET}"
fi

# Also remove old .smartsh if present
rm -rf "$HOME/.smartsh" 2>/dev/null || true

echo -e "\n${C_GREEN}🎉 TermPilot uninstalled cleanly. Reload your terminal session.${C_RESET}"
