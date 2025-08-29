#!/usr/bin/env bash
set -o pipefail

# --- Vérifications préalables ---

# Vérifier que Docker est présent et assez récent
if ! command -v docker &>/dev/null; then
  echo -e "\e[31mDocker n'est pas installé, abort.\e[0m"
  exit 1
fi

docker_version=$(docker version --format '{{.Server.Version}}' | cut -d '.' -f 1)
if [[ $docker_version -lt 24 ]]; then
  echo -e "\e[31mDocker version >= 24 requise.\e[0m"
  exit 1
fi

# Vérifier la présence des outils essentiels
for bin in openssl curl git awk sha1sum grep cut; do
  if ! command -v ${bin} &>/dev/null; then
    echo -e "\e[31m${bin} manquant, installe-le avec dnf install ${bin}\e[0m"
    exit 1
  fi
done

# Vérifier Docker Compose (plugin ou standalone)
if docker compose version --short 2>/dev/null | grep -q -E "^2."; then
  COMPOSE_VERSION=native
  echo -e "\e[32mDocker Compose plugin détecté.\e[0m"
elif docker-compose version --short 2>/dev/null | grep -q "^2."; then
  COMPOSE_VERSION=standalone
  echo -e "\e[32mDocker Compose standalone détecté.\e[0m"
else
  echo -e "\e[31mDocker Compose 2.x requis. Installe-le selon la doc : https://docs.docker.com/compose/install/\e[0m"
  exit 1
fi

# --- Config Mailcow ---
if [ -f mailcow.conf ]; then
  read -r -p "mailcow.conf existe déjà, le sauvegarder et écraser ? [y/N] " response
  case $response in
    [yY]*) mv mailcow.conf mailcow.conf_backup && chmod 600 mailcow.conf_backup ;;
    *) echo "Abort."; exit 1 ;;
  esac
fi

echo "Press enter pour confirmer les valeurs proposées ou entrer une valeur custom."

# Hostname (FQDN obligatoire)
while [ -z "${MAILCOW_HOSTNAME}" ]; do
  read -p "Hostname du serveur mail (FQDN, ex: mail.example.com): " -e MAILCOW_HOSTNAME
  if [[ ! "$MAILCOW_HOSTNAME" =~ \. ]]; then
    echo -e "\e[31mLe hostname doit être un FQDN valide.\e[0m"
    MAILCOW_HOSTNAME=""
  fi
done

# Timezone (détecte depuis RHEL)
DETECTED_TZ=$(timedatectl show -p Timezone --value 2>/dev/null)
while [ -z "${MAILCOW_TZ}" ]; do
  read -p "Timezone [${DETECTED_TZ}]: " -e MAILCOW_TZ
  [ -z "${MAILCOW_TZ}" ] && MAILCOW_TZ=${DETECTED_TZ}
done

# RAM pour décider ClamAV
MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$MEM_TOTAL" -le 2621440 ]; then
  read -r -p "Moins de 2.5GB RAM détectée. Désactiver ClamAV ? [Y/n] " resp
  [[ "$resp" =~ ^[nN]$ ]] && SKIP_CLAMD=n || SKIP_CLAMD=y
else
  SKIP_CLAMD=n
fi

# --- Génération mailcow.conf ---
cat << EOF > mailcow.conf
MAILCOW_HOSTNAME=${MAILCOW_HOSTNAME}
MAILCOW_PASS_SCHEME=BLF-CRYPT
DBNAME=mailcow
DBUSER=mailcow
DBPASS=$(openssl rand -base64 21)
DBROOT=$(openssl rand -base64 21)
REDISPASS=$(openssl rand -base64 21)
HTTP_PORT=80
HTTPS_PORT=443
TZ=${MAILCOW_TZ}
COMPOSE_PROJECT_NAME=mailcowdockerized
DOCKER_COMPOSE_VERSION=${COMPOSE_VERSION}
SKIP_CLAMD=${SKIP_CLAMD}
USE_WATCHDOG=y
EOF

chmod 600 mailcow.conf

echo -e "\e[32mConfiguration mailcow.conf générée avec succès pour RHEL.\e[0m"
