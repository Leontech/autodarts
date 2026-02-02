# Autodarts Ubuntu Setup

Automatizovaný instalační a stabilizační skript pro **Autodarts**  
(Ubuntu / Debian / Raspberry Pi OS)

---

## ✨ Co tento skript řeší

- stabilní názvy USB kamer (`/dev/autodarts_camX`)
- neblikající obraz (bez rozbití detekce)
- správné otevření přihlášení v grafickém prohlížeči
- zabránění vícenásobnému spouštění Autodarts procesů
- konzistentní chování po restartu systému

---

## 📋 Požadavky

- Ubuntu 20.04+ / Debian 11+ / Raspberry Pi OS (Bookworm)
- 3× USB kamera (UVC)
- připojení k internetu
- uživatel se `sudo` právy

---

## ⬇️ Stažení instalačního skriptu

```bash
cd ~
curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
chmod +x setup_autodarts.sh
