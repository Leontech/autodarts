Autodarts Ubuntu Setup

Automatizovaný instalační a stabilizační skript pro Autodarts na Ubuntu / Debian / Raspberry Pi OS.

Řeší nejčastější problémy:

nestabilní názvy kamer (/dev/videoX)

špatné nastavení expozice (blikání terče)

otevírání přihlášení v textovém prohlížeči (lynx)

automatické spouštění Autodarts procesů víckrát

rozdílné chování po rebootu

✨ Co skript dělá

📦 nainstaluje potřebné balíčky (v4l-utils, udev, xdg-utils)

🌐 nastaví Chromium jako výchozí prohlížeč (pokud je k dispozici)

🛑 vypne automatické spouštění konfliktních Autodarts služeb

🎥 vytvoří stabilní názvy kamer:

/dev/autodarts_cam1

/dev/autodarts_cam2

/dev/autodarts_cam3

⚙️ nastaví bezpečné výchozí parametry kamer (nebliká, UVC-safe)

🔁 vše aplikuje automaticky po každém bootu přes systemd

📋 Požadavky

Ubuntu 20.04+ / Debian 11+ / Raspberry Pi OS (Bookworm)

připojení k internetu

3× USB kamera (UVC)

uživatel s sudo právy

⬇️ Stažení skriptu
cd ~
curl -fsSL -o setup_autodarts.sh https://raw.githubusercontent.com/Leontech/autodarts/main/setup_autodarts.sh
chmod +x setup_autodarts.sh

🧪 Dry-run (doporučeno jako první krok)

Dry-run nic nemění, pouze ukáže, co by se provedlo:

sudo ./setup_autodarts.sh --dry-run


Výstup je označený:

[DRY-RUN] apt-get install -y v4l-utils xdg-utils udev


➡️ Ideální pro test na novém Ubuntu nebo před ostrým nasazením.

▶️ Ostré spuštění (reálná instalace)
sudo ./setup_autodarts.sh


Po dokončení není nutný reboot, ale doporučený.

🎥 Nastavení USB portů kamer (velmi důležité)

Každý počítač má jiné USB porty.
Nejprve si zjisti porty kamer:

udevadm info -a -n /dev/video0 | grep 'KERNELS=="[0-9]-[0-9].*:[0-9]\.[0-9]"'
udevadm info -a -n /dev/video2 | grep 'KERNELS=="[0-9]-[0-9].*:[0-9]\.[0-9]"'
udevadm info -a -n /dev/video4 | grep 'KERNELS=="[0-9]-[0-9].*:[0-9]\.[0-9]"'


Příklad výstupu:

KERNELS=="1-1:1.0"
KERNELS=="3-1:1.0"
KERNELS=="3-2:1.0"


Pak spusť skript s parametrem --ports:

sudo ./setup_autodarts.sh --ports "1-1:1.0,3-1:1.0,3-2:1.0"


➡️ Tím se správně přiřadí:

cam1 → levá kamera

cam2 → pravá kamera

cam3 → horní kamera

🧼 Bezpečné nastavení kamer (nebliká)

Skript NEPOUŽÍVÁ manuální expozici.

Používá pouze:

auto_exposure = 3 (Aperture Priority – stabilní)

exposure_dynamic_framerate = 0

white_balance_automatic = 1

Tyto hodnoty:

fungují s běžnými UVC kamerami

neblikají

nerozbijí detekci

Konfigurace se provádí skriptem:

/usr/local/bin/autodarts-cameras.sh


a je aplikována službou:

autodarts-cameras.service

🔁 systemd služba (kamera init)

Stav služby ověříš:

systemctl status autodarts-cameras.service


Ruční spuštění:

sudo systemctl restart autodarts-cameras.service


Log:

journalctl -u autodarts-cameras.service -n 50 --no-pager

🌐 Prohlížeč & přihlášení

Skript nastaví Chromium jako výchozí pro:

www-browser

x-www-browser

Ověření:

xdg-open https://autodarts.io


➡️ Musí se otevřít grafické okno Chromium, ne lynx.

🛑 Vypnutí automatických Autodarts služeb

Skript vypíná (pokud existují):

autodarts.service

darts-hub.service

autodarts-desktop.service

Updater zůstává zapnutý, pokud výslovně neřekneš jinak.

Vypnutí updateru:
sudo ./setup_autodarts.sh --disable-updater

📁 Co skript vytvoří / změní
Soubor / služba	Popis
/etc/udev/rules.d/99-autodarts-cameras.rules	stabilní názvy kamer
/usr/local/bin/autodarts-cameras.sh	init skript kamer
/etc/systemd/system/autodarts-cameras.service	systemd služba
update-alternatives	Chromium jako default
🔄 Jak změny vrátit zpět (ručně)
sudo systemctl disable --now autodarts-cameras.service
sudo rm /etc/systemd/system/autodarts-cameras.service
sudo rm /usr/local/bin/autodarts-cameras.sh
sudo rm /etc/udev/rules.d/99-autodarts-cameras.rules
sudo udevadm control --reload-rules

⚠️ Poznámky

Skript nenahrazuje Autodarts instalátor – pouze stabilizuje systém

Je safe pro opakované spuštění

Vhodné pro:

domácí setup

klub

turnajové zařízení

Raspberry Pi

🧑‍💻 Autor

Repo: https://github.com/Leontech/autodarts

Autor: Leontech
