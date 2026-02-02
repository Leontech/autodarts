# Autodarts Ubuntu Setup (SAFE camera version)

Automatizovaný instalační a stabilizační skript pro **Autodarts**
(Ubuntu / Debian / Raspberry Pi OS)

⚠️ Tato verze je **SAFE BY DEFAULT**  
➡️ **NEMĚNÍ žádná V4L2 nastavení kamer**, aby nedocházelo k falešným zásahům
(„ghost darts“).

---

## 📋 Požadavky

- Ubuntu 20.04+ / Debian 11+ / Raspberry Pi OS (Bookworm)
- 3× USB kamera (UVC)
- připojení k internetu
- uživatel se `sudo` právy

---

## 🎯 Co tento projekt řeší

- stabilní názvy USB kamer (`/dev/autodarts_cam1..3`)
- zabránění vícenásobnému spouštění Autodarts procesů
- správné otevření Autodarts přihlášení v grafickém prohlížeči
- konzistentní chování po rebootu
- **žádné zásahy do obrazu kamer (default)**

---

## ⬇️ KOMPLETNÍ POSTUP (JEDEN COPY – SHORA DOLŮ)

### 1️⃣ Stažení instalačního skriptu

    cd ~
    curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
    chmod +x setup_autodarts.sh

---

### 2️⃣ Testovací režim (DRY-RUN – nic nemění)

Doporučeno vždy spustit jako první.

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

### 5️⃣ Stav systemd služby pro kamery

    systemctl status autodarts-cameras.service

Log služby:

    journalctl -u autodarts-cameras.service -n 50 --no-pager

---

### 6️⃣ Test otevření Autodarts webu

    xdg-open https://autodarts.io

Musí se otevřít **grafické okno prohlížeče (Chromium)**.

---

## 🎥 Nastavení kamer – DŮLEŽITÉ

### ✅ Výchozí chování (doporučeno)

Projekt **NEMĚNÍ žádná V4L2 nastavení kamer**.

Důvod:
- změny expozice / frameratu / white balance
- mohou způsobit falešné detekce („ghost darts“)
- Autodarts funguje nejlépe s přirozeným obrazem z kamery

Výchozí skript pouze:
- ověří přítomnost kamer
- zapíše informaci do logu

Soubor:

    /usr/local/bin/autodarts-cameras.sh

---

### ⚠️ Pokročilé – manuální zásah (NA VLASTNÍ RIZIKO)

Pokud **VÍŠ, CO DĚLÁŠ**, můžeš ručně povolit zásah do kamer:

    sudo nano /usr/local/bin/autodarts-cameras.sh

Odkomentuj například:

    v4l2-ctl -d "$cam" -c auto_exposure=3

A restartuj službu:

    sudo systemctl restart autodarts-cameras.service

❗ Pokud se objeví falešné zásahy, vrať skript do původního stavu.

---

## 🛑 Zakázané automatické služby

Skript zakáže automatické spouštění těchto služeb (pokud existují):

- autodarts.service
- darts-hub.service
- autodarts-desktop.service

Updater **zůstává zapnutý**.

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
- Pouze stabilizuje systém a zařízení
- Bezpečné pro opakované spuštění
- Ověřeno na Raspberry Pi i PC

---

## 🧑‍💻 Autor

GitHub: https://github.com/Leontech/autodarts  
Autor: Leontech
