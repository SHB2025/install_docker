Video: https://youtu.be/-5pzmSATVLE

# install_docker
Skripta za automatsku instalaciju Docker-a na Ubuntu server.

# 🐳 install_docker.sh

Automatizirana Bash skripta za podešavanje Docker okruženja na Ubuntu serverima.

An automated Bash script for setting up a Docker environment on Ubuntu servers.

---

## 📥 Kako preuzeti i pokrenuti skriptu / How to download and run the script

    wget https://raw.githubusercontent.com/SHB2025/install_docker/refs/heads/main/install_docker.sh
    chmod +x install_docker.sh
    sudo ./install_docker.sh

## Opis:

📋 Koraci koje skripta izvršava / What the script does step-by-step
✅ Provjerava da li je skripta pokrenuta kao sudo ili root
✅ Checks if the script is run with sudo or root privileges

👤 Traži unos korisničkog imena i lozinke za novi account
👤 Prompts for a username and password for a new account

👨‍💻 Kreira novog korisnika (ako ne postoji) i dodaje ga u sudo i docker grupe
👨‍💻 Creates a new user (if it doesn't exist) and adds to sudo and docker groups

📦 Instalira osnovne pakete (curl, ca-certificates, gnupg, itd.)
📦 Installs essential packages (curl, ca-certificates, gnupg, etc.)

🔑 Dodaje Docker GPG ključ i repozitorij
🔑 Adds Docker GPG key and repository

🐳 Instalira Docker Engine i Docker CLI
🐳 Installs Docker Engine and Docker CLI

🔧 Preuzima i instalira najnoviju verziju Docker Compose-a
🔧 Downloads and installs the latest Docker Compose version

🧪 Provjerava instalaciju (docker --version, docker-compose --version)
🧪 Verifies installation with version checks

🔐 Provjerava da li je openssh-server instaliran i pokreće servis ako nije
🔐 Checks if openssh-server is installed and starts it if not

🚪 Provjerava trenutni SSH port i nudi opciju za promjenu
🚪 Checks current SSH port and offers option to change it

✅ Prikazuje završnu poruku — potrebno se ponovo prijaviti da bi promjene stupile na snagu
✅ Displays final message — re-login required for changes to take effect

🔐 Napomena / Important Note
Nakon instalacije, odjavite se i prijavite ponovo kako bi promjene stupile na snagu.
After installation, log out and log in again for changes to take effect.

Ako mijenjate SSH port, obavezno ažurirajte firewall pravila!
If you change the SSH port, make sure to update your firewall rules!

