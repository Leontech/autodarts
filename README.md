# Autodarts Ubuntu/Debian Setup Script

This repository contains a one-shot setup script to make Autodarts camera handling stable on Ubuntu/Debian systems.

It focuses on:
- stable camera device names (`/dev/autodarts_cam1..3`) via udev rules
- safe camera initialization at boot (systemd oneshot)
- preventing “double start” issues by disabling Autodarts auto-start services (except `darts-caller`)
- ensuring a GUI browser is used for OAuth/login (avoid `lynx` / terminal browser)

> **Security note:** Do not pass Autodarts passwords on the command line (they show up in `ps`).  
> Use the Desktop app login flow.

---

## Quick start (recommended)

Download and review the script:
```bash
curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
chmod +x setup_autodarts.sh
sudo ./setup_autodarts.sh
