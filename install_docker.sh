#!/bin/bash

# Provjera sudo statusa
# Check sudo status
if [ "$EUID" -ne 0 ]; then
  echo "Pokrenite ovu skriptu kao root ili sa sudo."
  echo "Run this script as root or with sudo."
  exit 1
fi

# Funkcija za unos lozinke sa zvjezdicama
# Function for entering passwords with asterisks
prompt_password() {
  local password
  unset password

  echo -n "Unesite lozinku za novi korisničkog računa: "
  echo -n "Enter password for new user account: "
  stty -echo
  while IFS= read -r -s -n 1 char; do
    if [[ $char == $'\0' ]]; then
      break
    fi
    if [[ $char == $'\177' ]]; then
      if [ -n "$password" ]; then
        echo -ne "\b \b"
        password=${password%?}
      fi
    else
      echo -n '*'
      password+=$char
    fi
  done
  stty echo
  echo
  REPLY=$password
}


# Upiši korisničko ime i lozinku za novi account
# Ask to enter username and password for new account
read -p "Unesite ime korisničkog računa kojeg želite kreirati i dodati u docker i sudo grupu (Enter the name of the user account you want to create and add to the docker and sudo groups): " username

# Provjera da li korisnik već postoji
# Check if the user already exists
if id "$username" &>/dev/null; then
  echo "Korisnički račun '$username' već postoji."
  echo "User account '$username' already exists."
  read -p "Da li želite koristiti postojeći korisnički račun? (da/ne)/Do you want to use an existing account? (yes=da/no=ne): " choice
  if [ "$choice" != "da" ]; then
    echo "Kreiranje korisničkog računa otkazano."
    echo "User account creation canceled."
    exit 1
  fi
else
  # Traži upisizanje lozinke za novog korisnika
  # Ask for a password for the new user
  prompt_password
  password=$REPLY
  # Kreiranje novog korisnika
  # Creating a new user
  sudo useradd -m -s /bin/bash $username
  echo "$username:$password" | sudo chpasswd
  # Dodavanje novog korisnika u sudo grupu
  sudo usermod -aG sudo $username
fi

# Ažuriranje liste paketa
# Updating the package list
sudo apt-get update

# Instalacija potrebnih paketa
# Installing required packages
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Dodavanje Docker-ovog GPG ključa
# Adding Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Dodavanje Docker-ovog repozitorija
# Adding the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Ažuriranje liste paketa s novim Docker repozitorijem
# Updating the package list with the new Docker repository
sudo apt-get update

# Instalacija najnovije verzije Docker-a
# Install the latest version of Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Kreiranje docker grupe (ako već ne postoji)
# Create a docker group (if it doesn't already exist)
if ! getent group docker; then
  sudo groupadd docker
fi

# Dodavanje korisnika u docker grupu, ako već nije dodan
# Add the user to the docker group, if not already added
if id -nG "$username" | grep -qw "docker"; then
  echo "Korisnik '$username' je već član docker grupe."
else
  sudo usermod -aG docker $username
fi

# Preuzimanje najnovije verzije Docker Compose-a
# Downloading the latest version of Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Davanje dozvola za izvršavanje Docker Compose-u
# Granting execution permissions to Docker Compose
sudo chmod +x /usr/local/bin/docker-compose

# Provjera instalacije
# Checking the installation
docker --version
docker-compose --version

echo "Instalacija je završena! Odjavite se i prijavite ponovo kako bi promjene stupile na snagu."
echo "Installation complete! Log out and log in again for the changes to take effect."

# Provjera da li je SSH servis instaliran
# Check if SSH service is installed
if ! command -v sshd &>/dev/null; then
  echo "SSH servis nije instaliran. Instaliram SSH servis..."
  echo "SSH service not installed. Installing SSH service..."
  sudo apt-get update
  sudo apt-get install -y openssh-server
  sudo systemctl enable ssh
  sudo systemctl start ssh
  echo "SSH servis je instaliran i pokrenut."
  echo "The SSH service is installed and running."
else
  echo "SSH servis je već instaliran."
  echo "The SSH service is already installed."
fi

# Provjera trenutnog SSH porta
# Checking the current SSH port
ssh_port=$(sudo grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
if [ -z "$ssh_port" ]; then
  ssh_port=22
fi

# Opcionalna promjena SSH porta
# Optional SSH port change
if [ "$ssh_port" -eq 22 ]; then
  echo "SSH koristi standardni port 22."
  echo "SSH uses standard port 22."
  read -p "Unesite prilagođeni port koji želite koristiti za SSH vezu(Enter the custom port you want to use for SSH connection): " new_port
  sudo sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config
  sudo sed -i "s/^Port 22/Port $new_port/" /etc/ssh/sshd_config
  sudo systemctl restart ssh
  echo "SSH port je postavljen na $new_port. Provjerite povezivanje preko novog porta."
  echo "SSH port set to $new_port. Check connection via new port."
else
  echo "SSH već koristi port $ssh_port."
  echo "SSH is already using port $ssh_port."
fi
