#!/usr/bin/env bash
set -euo pipefail

# Autodarts Ubuntu/Debian setup helper
# - Reinstall Autodarts Desktop (APT best-effort)
# - Disable any systemd services that auto-start Autodarts Desktop / hub (except darts-caller)
# - Create stable camera symlinks /dev/autodarts_cam1..3 via udev (by USB port path)
# - Apply SAFE camera controls at boot via systemd oneshot
# - Ensure GUI browser (www-browser/x-www-browser -> Chromium) to avoid OAuth opening in lynx
#
# Tested: Debian/Ubuntu-like systems (systemd + udev)

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
log()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==>${NC} $*"; }
err()  { echo -e "${RED}==>${NC} $*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Please run as root (use sudo)."
    exit 1
  fi
}

detect_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_LIKE="${ID_LIKE:-}"
  else
    OS_ID=""; OS_LIKE=""
  fi
}

apt_install_basics() {
  log "Installing base packages (v4l-utils, xdg-utils, udev)..."
  apt-get update -y
  apt-get install -y v4l-utils xdg-utils udev
}

install_chromium_if_available() {
  if have_cmd chromium-browser || have_cmd chromium; then
    log "Chromium already installed."
    return 0
  fi

  warn "Chromium not found. Trying to install it (best-effort)."
  if apt-get install -y chromium-browser >/dev/null 2>&1; then
    log "Installed chromium-browser."
  elif apt-get install -y chromium >/dev/null 2>&1; then
    log "Installed chromium."
  else
    warn "Could not install Chromium automatically. Install it manually if you need OAuth login in GUI."
  fi
}

ensure_www_browser_points_to_chromium() {
  local chromium_path=""

  if have_cmd chromium-browser; then
    chromium_path="$(command -v chromium-browser)"
  elif have_cmd chromium; then
    chromium_path="$(command -v chromium)"
  else
    warn "Chromium not installed; skipping browser alternatives setup."
    return 0
  fi

  log "Setting www-browser/x-www-browser alternatives to Chromium (${chromium_path})."

  update-alternatives --install /usr/bin/www-browser www-browser "${chromium_path}" 200 || true
  update-alternatives --install /usr/bin/x-www-browser x-www-browser "${chromium_path}" 200 || true

  update-alternatives --auto www-browser || true
  update-alternatives --auto x-www-browser || true
}

# --- Disable auto-start services for Autodarts Desktop / hub (except darts-caller) ---
disable_autostart_services() {
  log "Disabling services that may auto-start Autodarts Desktop / hub (except darts-caller)."

  # Known/common units in some installs
  local units=(
    "autodarts.service"
    "autodartsupdater.service"
    "darts-hub.service"
    "autodarts-desktop.service"
  )

  for u in "${units[@]}"; do
    if systemctl list-unit-files --type=service | awk '{print $1}' | grep -qx "${u}"; then
      warn "Disabling ${u}"
      systemctl disable --now "${u}" || true
      # Mask updater only if you really don't want it
      # We'll mask only autodarts.service & darts-hub.service (avoid surprises)
      if [[ "${u}" == "autodarts.service" || "${u}" == "darts-hub.service" ]]; then
        systemctl mask "${u}" || true
      fi
    fi
  done

  # Also stop any currently running instances started by services
  systemctl stop autodarts.service 2>/dev/null || true
  systemctl stop darts-hub.service 2>/dev/null || true
}

# --- Reinstall Autodarts Desktop (best-effort via APT) ---
reinstall_autodarts_desktop() {
  log "Attempting to (re)install Autodarts Desktop (APT best-effort)."

  # Some systems have package names like: autodarts-desktop, autodarts
  # We'll try reinstall first if already installed; else install.
  if dpkg -l | awk '{print $2}' | grep -qx "autodarts-desktop"; then
    log "Package autodarts-desktop is installed -> reinstalling."
    apt-get install -y --reinstall autodarts-desktop || warn "Reinstall autodarts-desktop failed."
    return 0
  fi

  if dpkg -l | awk '{print $2}' | grep -qx "autodarts"; then
    log "Package autodarts is installed -> reinstalling."
    apt-get install -y --reinstall autodarts || warn "Reinstall autodarts failed."
    return 0
  fi

  # Not installed -> try install
  if apt-get install -y autodarts-desktop >/dev/null 2>&1; then
    log "Installed autodarts-desktop."
  elif apt-get install -y autodarts >/dev/null 2>&1; then
    log "Installed autodarts."
  else
    warn "Could not install Autodarts Desktop via APT."
    warn "If you installed it manually (AppImage/manual), this is expected."
  fi
}

# --- UDEV stable camera symlinks ---
write_udev_rules() {
  local rules_file="/etc/udev/rules.d/99-autodarts-cameras.rules"

  log "Writing udev rules for /dev/autodarts_cam1..3 (${rules_file})."
  cat > "${rules_file}" <<'EOF'
# Autodarts stable camera symlinks
#
# Adjust KERNELS==... to match your USB topology if needed.
# Find port path with:
#   udevadm info -a -n /dev/videoX | grep 'KERNELS=="[0-9]-[0-9].*:[0-9]\.[0-9]"'
#
# Example mapping:
#   cam1 -> KERNELS=="1-1:1.0"
#   cam2 -> KERNELS=="3-1:1.0"
#   cam3 -> KERNELS=="3-2:1.0"

SUBSYSTEM=="video4linux", KERNEL=="video*", KERNELS=="1-1:1.0", SYMLINK+="autodarts_cam1"
SUBSYSTEM=="video4linux", KERNEL=="video*", KERNELS=="3-1:1.0", SYMLINK+="autodarts_cam2"
SUBSYSTEM=="video4linux", KERNEL=="video*", KERNELS=="3-2:1.0", SYMLINK+="autodarts_cam3"
EOF

  chmod 0644 "${rules_file}"
}

reload_udev_and_trigger() {
  log "Reloading udev rules and triggering..."
  udevadm control --reload-rules
  udevadm trigger --subsystem-match=video4linux
  sleep 1
}

# --- SAFE camera settings at boot ---
write_camera_script() {
  local script="/usr/local/bin/autodarts-cameras.sh"
  log "Writing SAFE camera init script (${script})."
  cat > "${script}" <<'EOF'
#!/bin/bash
# SAFE camera init for Autodarts (UVC-friendly)
# Keep auto-exposure on (stable), disable dynamic framerate.
set -e

sleep 2

for cam in /dev/autodarts_cam1 /dev/autodarts_cam2 /dev/autodarts_cam3; do
  [ -e "$cam" ] || continue
  echo "Configuring $cam"
  v4l2-ctl -d "$cam" -c auto_exposure=3 || true
  v4l2-ctl -d "$cam" -c exposure_dynamic_framerate=0 || true
  v4l2-ctl -d "$cam" -c white_balance_automatic=1 || true
done
EOF
  chmod +x "${script}"
}

write_systemd_camera_service() {
  local unit="/etc/systemd/system/autodarts-cameras.service"
  log "Writing systemd service (${unit})."
  cat > "${unit}" <<'EOF'
[Unit]
Description=Autodarts camera stable settings
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/autodarts-cameras.sh

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable autodarts-cameras.service
  systemctl restart autodarts-cameras.service
}

show_status() {
  echo
  log "Status summary:"
  echo "Symlinks:"
  ls -l /dev/autodarts_cam* 2>/dev/null || warn "Symlinks not present yet (unplug/replug cameras or reboot)."
  echo
  log "Camera service:"
  systemctl status autodarts-cameras.service --no-pager || true
  echo
  warn "If your USB topology differs, edit /etc/udev/rules.d/99-autodarts-cameras.rules (KERNELS==...)."
}

main() {
  require_root
  detect_os

  if [[ "${OS_ID:-}" != "ubuntu" && "${OS_ID:-}" != "debian" && "${OS_LIKE:-}" != *"debian"* ]]; then
    warn "This script targets Ubuntu/Debian-like systems. Continuing anyway..."
  fi

  apt_install_basics
  install_chromium_if_available
  ensure_www_browser_points_to_chromium

  # Stop/disable autostart services that can cause double-start issues
  disable_autostart_services

  # Reinstall desktop (best-effort via APT)
  reinstall_autodarts_desktop

  # Stable cameras + safe boot settings
  write_udev_rules
  reload_udev_and_trigger
  write_camera_script
  write_systemd_camera_service

  show_status

  log "Done."
  warn "If symlinks are missing, reboot once or unplug/replug cameras."
}

main "$@"
