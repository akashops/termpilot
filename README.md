# ⚡ TermPilot

> **Open-Source Universal Terminal Copilot & Intelligent Command Assistant for Linux (Bash, Zsh, Fish)**

[![Linux](https://img.shields.io/badge/OS-Linux%20%7C%20macOS-blue.svg)](https://kernel.org)
[![Shells](https://img.shields.io/badge/Shells-Bash%20%7C%20Zsh%20%7C%20Fish-green.svg)](https://gnu.org/software/bash)
[![Latency](https://img.shields.io/badge/Latency-%3C2ms-brightgreen.svg)]()
[![Open Source](https://img.shields.io/badge/Open--Source-100%25-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**TermPilot** is a lightweight, zero-dependency, open-source terminal enhancement suite that elevates your shell into an intelligent developer environment. It brings **Kali Linux & Fish-style real-time ghost suggestions**, **interactive 1-key typo auto-corrections**, **deep subcommand validation (Git, Docker, Kubernetes, Systemd)**, and **safety guardrails** to any Linux distribution or terminal.

👉 **[Read the Full Architecture & How It Works Guide (with diagrams)](./HOW_TO_WORK.md)**  
🤝 **[Read the Contributing & Customization Guide](./CONTRIBUTING.md)**

---

## 🌟 Key Features

1. **⚡ Real-Time Ghost Suggestions**
   - Type the first letter of any command and see greyed-out completions from your history and 250+ system tools.
   - Accept with **Right Arrow (`→`)**, **`Ctrl+F`**, or **`Tab`**.

2. **⌨️ Interactive 1-Key Quick Execution (`[1]`, `[2]`, `[3]`)**
   - On typos, TermPilot suggests the closest commands. Just press **`1`**, **`2`**, or **`3`** to **instantly run** without retyping.

3. **🧠 Deep Subcommand & Context Intelligence**
   - Intercepts typos in subcommands and flags:
     - `git pus` ➜ `💡 Deep Context (git): Did you mean 'git push'?`
     - `docker imags` ➜ `💡 Deep Context (docker): Did you mean 'docker images'?`
     - `systemctl staus` ➜ `💡 Deep Context (systemctl): Did you mean 'systemctl status'?`
     - `kubectl get pds` ➜ `💡 Deep Context (kubectl): Did you mean 'kubectl get pods'?`
   - **Local Path Resolution:** If you run `deploy.sh` without `./`, TermPilot detects it and suggests `./deploy.sh`.

4. **🛡️ Enterprise Security Guardrail & History Audit**
   - **Guardrail:** Intercepts accidental catastrophic commands (e.g., `rm -rf /`, `chmod -R 777 /`).
   - **`termpilot audit`:** Scans shell history for exposed tokens, API keys, and passwords.

5. **⚡ Sub-2ms High-Speed Binary Cache**
   - Indexed binary caching guarantees **<2ms latency** even on servers with 10,000+ binaries.

6. **🛠️ 100% Open-Source & Custom-Tool Friendly**
   - Easily add your company's custom internal CLI tools:
     ```bash
     termpilot add "deploy-app|DevOps|Deploy microservice to staging|deploy-app --env staging"
     ```

---

## 📥 Universal 1-Click Installation

Clone and install:
```bash
git clone https://github.com/akashops/termpilot.git
cd termpilot
bash install.sh
```

Activate in your current shell:
```bash
source ~/.bashrc   # For Bash
# OR
source ~/.zshrc    # For Zsh
# OR
source ~/.config/fish/config.fish # For Fish
```

---

## 🎮 CLI Management Commands

```bash
termpilot doctor         # Run system & performance diagnostics
termpilot audit          # Audit shell history for leaked credentials
termpilot stats          # View command usage analytics & top tools
termpilot add <entry>    # Add custom command to local cheatsheet database
termpilot custom         # List all custom commands
termpilot info <cmd>     # View command description & flags
termpilot search <query> # Search 250+ command cheatsheet database
? <cmd>                  # Quick cheatsheet alias (e.g. ? docker, ? iptables, ? tar)
```

---

## ⚙️ Configuration

Customize your settings in `~/.termpilot/config/termpilot.conf`:
```bash
TERMPILOT_AUTOSUGGEST_ENABLED=true
TERMPILOT_SUGGESTION_COLOR="242"
TERMPILOT_INTERACTIVE_FIX=true
TERMPILOT_SECURITY_GUARD=true
TERMPILOT_PATH_AWARE_ENABLED=true
```

---

## 🤝 Contributing & Community
TermPilot is built for the developer community. Feel free to open issues, submit pull requests, or add new command cheatsheets! See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

## 📄 License
Released under the [MIT License](LICENSE).
