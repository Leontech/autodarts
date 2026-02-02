#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    *)
      ;;
  esac
done

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
log()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==>${NC} $*"; }
err()  { echo -e "${RED}==>${NC} $*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

require_root() {
  if [ "${EUID}" -ne 0 ]; then
    err "Please run as root (use sudo)."
    exit 1
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

log "Autodarts setup starting"
[ "$DRY_RUN" -eq 1 ] && warn "Running in DRY-RUN mode (no changes will be made)"

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------
log "Installing base packages"
run "apt-get update -y"
run "apt-get install -y v4l-utils xdg-utils udev"

# ------------------------------------------------------------
# Browser (Chromium)
# ------------------------------------------------------------
if have_cmd chromium-browser; then
  CHROMIUM=$(command -v chromium-browser)
elif have_cmd chromium; then
  CHROMIUM=$(command -v chromium)
else
  warn "Chromium not found – attempting install"
  run "apt-get install -y chromium-browser || apt-get install -y chromium"
  CHROMIUM=$(command -v chromium-browser || command -v chromium || true)
fi

if [ -n "${CHROMIUM:-}" ]; then
  log "Setting default browser to Chromium"
  run "update-alternatives --install /usr/bin/www-browser www-browser $CHROMIUM 200"
  run "update-alternatives --install /usr/bin/x-www-browser x-www-browser $CHROMIUM 200"
  run "update-alternatives --auto www-browser"
  run "update-alternatives --auto x-www-browser"
fi

# ------------------------------------------------------------
# Disable conflicting Autodarts services
# ------------------------------------------------------------
for svc in autodarts.service darts-hub.service autodartsupdater.service autodarts-desktop.service; do
  if systemctl list-unit-files | awk '{print $1}' | grep -qx "$svc"; then
    warn "Disabling service: $svc"
    run "systemctl disable --now $svc"
    case "$svc" in
      autodarts.service|darts-hub.service)
        run "systemctl mask $svc"
        ;;
    esac
  fi
done

# ------------------------------------------------------------
# udev camera rules
# ------------------------------------------------------------
log "Writing udev rules for stable camera names"
run "cat > /etc/udev/rules.d/99-autodarts-cameras.rules <<'EOF'
SUBSYSTEM==\"video4linux\", KERNEL==\"video*\", KERNELS==\"1-1:1.0\", SYMLINK+=\"autodarts_cam1\"
SUBSYSTEM==\"video4linux\", KERNEL==\"video*\", KERNELS==\"3-1:1.0\", SYMLINK+=\"autodarts_cam2\"
SUBSYSTEM==\"video4linux\", KERNEL==\"video*\", KERNELS==\"3-2:1.0\", SYMLINK+=\"autodarts_cam3\"
EOF"

run "udevadm control --reload-rules"
run "udevadm trigger --subsystem-match=video4linux"

# ------------------------------------------------------------
# Camera init script
# ------------------------------------------------------------
log "Installing camera init script"
run "cat > /usr/local/bin/autodarts-cameras.sh <<'EOF'
#!/bin/bash
sleep 2
for cam in /dev/autodarts_cam1 /dev/autodarts_cam2 /dev/autodarts_cam3; do
  [ -e \"\$cam\" ] || continue
  v4l2-ctl -d \"\$cam\" -c auto_exposure=3 || true
  v4l2-ctl -d \"\$cam\" -c exposure_dynamic_framerate=0 || true
  v4l2-ctl -d \"\$cam\" -c white_balance_automatic=1 || true
done
EOF"

run "chmod +x /usr/local/bin/autodarts-cameras.sh"

# ------------------------------------------------------------
# systemd service
# ------------------------------------------------------------
log "Installing systemd camera service"
run "cat > /etc/systemd/system/autodarts-cameras.service <<'EOF'
[Unit]
Description=Autodarts camera stable settings
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/autodarts-cameras.sh

[Install]
WantedBy=multi-user.target
EOF"

run "systemctl daemon-reload"
run "systemctl enable autodarts-cameras.service"
run "systemctl restart autodarts-cameras.service"

log "Autodarts setup finished"
[ "$DRY_RUN" -eq 1 ] && warn "No changes were made (dry-run)"
