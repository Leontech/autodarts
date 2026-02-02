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

## ⬇️ Kompletní postup (DRY-RUN → instalace → ověření → UNDO)

Vše je psané tak, aby šlo jet **shora dolů bez přemýšlení**.

### 1️⃣ Stažení instalačního skriptu

    cd ~
    curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
    chmod +x setup_autodarts.sh

---

### 2️⃣ Testovací režim (DRY-RUN)

Dry-run **nic nemění**, pouze vypíše, co by skript provedl.

    sudo ./setup_autodarts.sh --dry-run

Pokud výstup dává smysl, pokračuj instalací.

---

### 3️⃣ Ostré spuštění (reálná instalace)

    sudo ./setup_autodarts.sh

Po dokončení je **doporučený restart systému**.

---

### 4️⃣ Ověření stabilních názvů kamer

    ls -l /dev/autodarts_cam*

Očekávaný výstup:

    /dev/autodarts_cam1
    /dev/autodarts_cam2
    /dev/autodarts_cam3

---

### 5️⃣ Ověření nastavení kamer (bez blikání)

    v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=auto_exposure
    v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=exposure_dynamic_framerate
    v4l2-ctl -d /dev/autodarts_cam1 --get-ctrl=white_balance_automatic

Správné hodnoty:

    auto_exposure: 3
    exposure_dynamic_framerate: 0
    white_balance_automatic: 1

---

### 6️⃣ Stav systemd služby pro kamery

    systemctl status autodarts-cameras.service

Log služby:

    journalctl -u autodarts-cameras.service -n 50 --no-pager

---

### 7️⃣ Test otevření Autodarts webu

    xdg-open https://autodarts.io

Musí se otevřít **grafické okno prohlížeče (Chromium)**.

---

## 🔄 UNDO – kompletní odebrání změn

Pokud se chceš vrátit do původního stavu:

    sudo systemctl disable --now autodarts-cameras.service
    sudo rm -f /etc/systemd/system/autodarts-cameras.service
    sudo rm -f /usr/local/bin/autodarts-cameras.sh
    sudo rm -f /etc/udev/rules.d/99-autodarts-cameras.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=video4linux

---

## ⚠️ Poznámky

- Skript **neinstaluje Autodarts Desktop**
- Pouze:
  - stabilizuje USB kamery
  - nastaví bezpečné V4L2 hodnoty
  - zabrání vícenásobnému startu služeb
- Bezpečné pro opakované spuštění
- Ověřeno na Raspberry Pi i PC

---

## 🧑‍💻 Autor

GitHub: https://github.com/Leontech/autodarts  
Autor: Leontech
