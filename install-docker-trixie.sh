#!/usr/bin/env bash
# ==============================================================================
#  install-docker-trixie.sh
#  Installation automatique de Docker CE sur Debian 13 Trixie (sans GUI)
#  Usage : sudo bash install-docker-trixie.sh [--user <username>]
# ==============================================================================

set -euo pipefail

# ── Couleurs ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[✔]${RESET} $*"; }
info() { echo -e "${CYAN}[➜]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
die()  { echo -e "${RED}[✘]${RESET} $*" >&2; exit 1; }

# ── Vérifications préalables ────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && die "Ce script doit être exécuté en tant que root (sudo)."

DISTRO_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
DISTRO_VER=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')

[[ "$DISTRO_ID" != "debian" ]] && die "Ce script cible Debian uniquement (détecté : $DISTRO_ID)."
[[ "$DISTRO_VER" != "trixie" ]] && warn "Codename détecté : '$DISTRO_VER' — le script est optimisé pour 'trixie'."

# ── Argument optionnel : utilisateur à ajouter au groupe docker ─────────────
TARGET_USER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) TARGET_USER="$2"; shift 2 ;;
    *) die "Argument inconnu : $1" ;;
  esac
done

# Si non spécifié, tente de déduire l'utilisateur réel (hors root)
if [[ -z "$TARGET_USER" ]]; then
  TARGET_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-}")
fi

# ── Bannière ────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Docker CE — Debian 13 Trixie — Installer${RESET}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${RESET}\n"

# ── 1. Mise à jour du système ───────────────────────────────────────────────
info "Mise à jour des paquets système..."
apt-get update -qq
apt-get upgrade -y -qq
log "Système à jour."

# ── 2. Dépendances de base ──────────────────────────────────────────────────
info "Installation des dépendances..."
apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common
log "Dépendances installées."

# ── 3. Clé GPG officielle Docker ────────────────────────────────────────────
info "Ajout de la clé GPG Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
log "Clé GPG ajoutée."

# ── 4. Dépôt Docker (forcé sur trixie) ─────────────────────────────────────
info "Configuration du dépôt Docker pour Trixie..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian trixie stable" \
  > /etc/apt/sources.list.d/docker.list
log "Dépôt configuré."

# ── 5. Installation Docker CE ───────────────────────────────────────────────
info "Installation de Docker CE..."
apt-get update -qq
apt-get install -y -qq \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
log "Docker CE installé."

# ── 6. Activation et démarrage du service ───────────────────────────────────
info "Activation de Docker au démarrage (systemd)..."
systemctl enable docker
systemctl start docker
log "Service Docker actif."

# ── 7. Ajout de l'utilisateur au groupe docker ───────────────────────────────
if [[ -n "$TARGET_USER" ]] && id "$TARGET_USER" &>/dev/null; then
  info "Ajout de '$TARGET_USER' au groupe docker..."
  usermod -aG docker "$TARGET_USER"
  log "Utilisateur '$TARGET_USER' ajouté au groupe docker."
  warn "La session doit être rechargée (newgrp docker ou reconnexion) pour prendre effet."
else
  warn "Aucun utilisateur ajouté au groupe docker (spécifier --user <nom>)."
fi

# ── 8. Vérification finale ───────────────────────────────────────────────────
info "Vérification de l'installation..."
DOCKER_VERSION=$(docker --version)
log "$DOCKER_VERSION"
docker run --rm hello-world 2>&1 | grep -q "Hello from Docker" \
  && log "Test hello-world : OK ✔" \
  || warn "Test hello-world non concluant — vérifiez manuellement."

# ── 9. Récapitulatif ─────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}══════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Installation terminée avec succès !${RESET}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${RESET}"
echo -e "  ${BOLD}docker version${RESET}        : $(docker --version)"
echo -e "  ${BOLD}docker compose version${RESET}: $(docker compose version)"
echo -e "  ${BOLD}Service systemd${RESET}       : $(systemctl is-active docker)"
[[ -n "$TARGET_USER" ]] && \
  echo -e "  ${BOLD}Utilisateur docker${RESET}    : $TARGET_USER"
echo ""
