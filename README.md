# Autodarts Ubuntu Setup

Automatizovaný instalační a stabilizační skript pro Autodarts
(Ubuntu / Debian / Raspberry Pi OS)

---

## 📋 Požadavky

- Ubuntu 20.04+ / Debian 11+ / Raspberry Pi OS (Bookworm)
- 3× USB kamera (UVC)
- připojení k internetu
- uživatel se sudo právy

---

## ⬇️ Stažení skriptu + test (DRY-RUN) + instalace + ověření + UNDO
(VŠE V JEDNOM BLOKU – kopíruj shora dolů)

```bash
# 1) Stažení instalačního skriptu
cd ~
curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
chmod +x setup_autodarts.sh

# 2) DRY-RUN (nic nemění, jen vypíše akce)
sudo ./setup_autodarts.sh --dry-run

# 3) OSTRÉ SPUŠTĚNÍ (reálná instalace)
sudo ./setup_autodarts.sh

# 4) Ověření stabilních názvů kamer
ls -l /dev/autodarts_cam*

# očekávaný výstup:
# /dev/autodarts_cam1
# /dev/autodarts_cam2
# /dev/autodarts_cam3

# 5) Ověření nastavení kamer (bez blikání)
v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=auto_exposure
v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=exposure_dynamic_framerate
v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=white_balance_automatic

# správné hodnoty:
# auto_exposure: 3
# exposure_dynamic_framerate: 0
# white_balance_automatic: 1

# 6) Stav systemd služby pro kamery
systemctl status autodarts-cameras.service

# 7) Log služby
journalctl -u autodarts-cameras.service -n 50 --no-pager

# 8) Test otevření Autodarts webu (musí se otevřít grafické okno Chromium)
xdg-open https://autodarts.io

# -------------------------------------------------------------------
# 9) UNDO – kompletní odebrání změn (pokud se chceš vrátit zpět)
# -------------------------------------------------------------------

sudo systemctl disable --now autodarts-cameras.service
sudo rm -f /etc/systemd/system/autodarts-cameras.service
sudo rm -f /usr/local/bin/autodarts-cameras.sh
sudo rm -f /etc/udev/rules.d/99-autodarts-cameras.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=video4linux

