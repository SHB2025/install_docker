#!/bin/bash

# Provjera sudo statusa
if [ "$EUID" -ne 0 ]; then
  echo "Pokrenite ovu skriptu kao root ili sa sudo."
  exit 1
fi

# Funkcija za unos lozinke sa zvjezdicama
prompt_password() {
  local password
  unset password

  echo -n "Unesite lozinku za novog korisničkog računa: "
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


# Traženje korisničkog imena i lozinke
read -p "Unesite ime korisničkog računa kojeg želite kreirati i dodati u docker i sudo grupu: " username

# Provjera da li korisnik već postoji
if id "$username" &>/dev/null; then
  echo "Korisnički račun '$username' već postoji."
  read -p "Da li želite koristiti postojeći korisnički račun? (da/ne): " choice
  if [ "$choice" != "da" ]; then
    echo "Kreiranje korisničkog računa otkazano."
    exit 1
  fi
else
  # Traženje lozinke za novog korisnika
  prompt_password
  password=$REPLY
  # Kreiranje novog korisnika
  sudo useradd -m -s /bin/bash $username
  echo "$username:$password" | sudo chpasswd
  # Dodavanje novog korisnika u sudo grupu
  sudo usermod -aG sudo $username
fi

# Ažuriranje liste paketa
sudo apt-get update

# Instalacija potrebnih paketa
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Dodavanje Docker-ovog GPG ključa
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Dodavanje Docker-ovog repozitorija
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Ažuriranje liste paketa s novim Docker repozitorijem
sudo apt-get update

# Instalacija najnovije verzije Docker-a
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Kreiranje docker grupe (ako već ne postoji)
if ! getent group docker; then
  sudo groupadd docker
fi

# Dodavanje korisnika u docker grupu, ako već nije dodan
if id -nG "$username" | grep -qw "docker"; then
  echo "Korisnik '$username' je već član docker grupe."
else
  sudo usermod -aG docker $username
fi

# Preuzimanje najnovije verzije Docker Compose-a
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Davanje dozvola za izvršavanje Docker Compose-u
sudo chmod +x /usr/local/bin/docker-compose

# Provjera instalacije
docker --version
docker-compose --version

echo "Instalacija je završena! Odjavite se i prijavite ponovo kako bi promjene stupile na snagu."

# Provjera da li je SSH servis instaliran
if ! command -v sshd &>/dev/null; then
  echo "SSH servis nije instaliran. Instaliram SSH servis..."
  sudo apt-get update
  sudo apt-get install -y openssh-server
  sudo systemctl enable ssh
  sudo systemctl start ssh
  echo "SSH servis je instaliran i pokrenut."
else
  echo "SSH servis je već instaliran."
fi

# Provjera trenutnog SSH porta
ssh_port=$(sudo grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
if [ -z "$ssh_port" ]; then
  ssh_port=22
fi

# Opcionalna promjena SSH porta
if [ "$ssh_port" -eq 22 ]; then
  echo "SSH koristi standardni port 22."
  read -p "Unesite drugi port koji želite postaviti za SSH: " new_port
  sudo sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config
  sudo sed -i "s/^Port 22/Port $new_port/" /etc/ssh/sshd_config
  sudo systemctl restart ssh
  echo "SSH port je postavljen na $new_port. Provjerite povezivanje preko novog porta."
else
  echo "SSH već koristi port $ssh_port."
fi
