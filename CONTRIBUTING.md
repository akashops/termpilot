# 🤝 Contributing to TermPilot

Thank you for your interest in contributing to **TermPilot**! As an open-source project, TermPilot is designed to be modular, hackable, and easy for any developer to customize.

---

## 🏗️ Project Architecture Overview

```
termpilot/
├── bin/
│   └── termpilot-helper.sh   # Main CLI logic, fuzzy matching & diagnostic tools
├── core/
│   ├── autosuggest.bash      # Readline engine for Bash users
│   ├── autosuggest.zsh       # ZLE ghost-text widget for Zsh users
│   ├── autosuggest.fish      # Fish shell integration
│   ├── error_handler.sh      # Hook for command_not_found interception
│   ├── universal_compat.sh   # Terminal color & capability auto-detector
│   └── cheatsheet.db         # Core command database
├── config/
│   ├── termpilot.conf        # Default configuration
│   └── custom_commands.db    # User-added custom commands
├── termpilot.plugin.sh       # Sourced entrypoint
├── install.sh                # 1-Click universal installer
└── uninstall.sh              # Clean uninstaller
```

---

## 🛠️ How to Customize & Extend

### 1. Adding New Commands to the Cheatsheet Database
You can contribute directly to `core/cheatsheet.db` or add custom commands locally using:
```bash
termpilot add "mytool|Category|Short description of command|mytool --flag example"
```

**Database Format:**
```
command_name|Category|Short 1-line description|Example usage flags
```

---

### 2. Adding Deep Context for New CLI Tools
To add deep context support for a new CLI (e.g. `terraform`, `ansible`, `aws`):
1. Open `bin/termpilot-helper.sh`.
2. Locate the `analyze_deep_subcommand()` function.
3. Add your tool's subcommands:
```bash
terraform)
    valid_subs=(init plan apply destroy validate state output import fmt)
    ;;
```

---

### 3. Customizing Themes & Colors
Edit `~/.termpilot/config/termpilot.conf` or `core/universal_compat.sh` to adjust ANSI 256 or TrueColor values.

---

## 🧪 Testing Your Changes Locally

Run the built-in diagnostic test:
```bash
termpilot doctor
```

Test fuzzy typo lookup:
```bash
bash bin/termpilot-helper.sh suggest "gerp"
```

Test cheatsheet search:
```bash
bash bin/termpilot-helper.sh info "docker"
```

---

## 📜 Pull Request Guidelines
1. Keep dependencies at **Zero** (Pure POSIX/Bash/Zsh compatibility).
2. Avoid external heavy runtimes (no Node/Python requirements for core execution).
3. Ensure backwards compatibility with Bash 3.2+ (macOS standard) and Zsh 5.0+.

---

## 📄 License
By contributing to TermPilot, you agree that your contributions will be licensed under the [MIT License](LICENSE).
