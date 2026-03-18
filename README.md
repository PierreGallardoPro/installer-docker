# 🐳 Docker CE — Debian 13 Trixie — Auto-Installer

Installation automatique et silencieuse de **Docker CE** sur une machine **Debian 13 Trixie** (sans interface graphique), dès les premiers instants du premier démarrage.

---

## 📁 Fichiers fournis

| Fichier | Rôle |
|---|---|
| `install-docker-trixie.sh` | Script principal d'installation de Docker |
| `docker-firstboot.service` | Service systemd pour lancer l'installation au 1er boot |

---

## ✅ Prérequis

- Debian 13 **Trixie** (version minimale, sans GUI)
- Connexion internet active au moment de l'installation
- Droits **root** ou **sudo**

---

## 🚀 Utilisation

### Option A — Installation manuelle

Une fois connecté à la machine, exécuter directement :

```bash
sudo bash install-docker-trixie.sh --user <votre_utilisateur>
```

L'argument `--user` est optionnel. S'il est omis, le script tente de détecter automatiquement l'utilisateur courant (via `$SUDO_USER` ou `logname`).

---

### Option B — Installation automatique au 1er démarrage *(recommandé)*

Cette méthode est idéale pour préparer une image, un modèle de VM, ou un serveur déployé automatiquement.

#### Étape 1 — Copier le script d'installation

```bash
sudo cp install-docker-trixie.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/install-docker-trixie.sh
```

#### Étape 2 — Installer le service systemd

```bash
sudo cp docker-firstboot.service /etc/systemd/system/
sudo systemctl enable docker-firstboot.service
```

#### Étape 3 — Redémarrer

```bash
sudo reboot
```

Au prochain démarrage, systemd attendra que le réseau soit disponible, puis lancera l'installation automatiquement. Le service **se désactive tout seul** après une exécution réussie — il ne s'exécutera jamais deux fois.

---

## 🔧 Ce que fait le script, étape par étape

| # | Action |
|---|---|
| 1 | `apt update` + `apt upgrade` — mise à jour du système |
| 2 | Installation des dépendances (`curl`, `gnupg`, `ca-certificates`, etc.) |
| 3 | Téléchargement et ajout de la **clé GPG officielle Docker** |
| 4 | Configuration du **dépôt stable Docker** pour Trixie |
| 5 | Installation de `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` |
| 6 | Activation du service Docker au démarrage (`systemctl enable`) |
| 7 | Ajout de l'utilisateur cible au groupe `docker` (accès sans `sudo`) |
| 8 | Test de bon fonctionnement via l'image `hello-world` |
| 9 | Affichage d'un récapitulatif des versions installées |

---

## ⚙️ Comportement du service systemd

Le fichier `docker-firstboot.service` est conçu avec les garanties suivantes :

- **`After=network-online.target`** — attend que le réseau soit opérationnel avant de démarrer
- **`ConditionPathExists=!/usr/bin/docker`** — ne s'exécute **pas** si Docker est déjà installé
- **`ExecStartPre=/bin/sleep 5`** — laisse 5 secondes supplémentaires au réseau pour se stabiliser
- **`ExecStartPost=systemctl disable`** — se **désactive automatiquement** après une exécution réussie
- **Journalisation** dans `/var/log/docker-firstboot.log`

---

## 📋 Vérification post-installation

```bash
# Version de Docker
docker --version

# Version de Docker Compose
docker compose version

# Statut du service
systemctl status docker

# Test rapide
docker run --rm hello-world

# Consulter les logs du premier démarrage
cat /var/log/docker-firstboot.log
```

---

## 👤 Accès Docker sans sudo

Si l'utilisateur a été correctement ajouté au groupe `docker`, il faut **recharger la session** pour que le changement prenne effet :

```bash
# Option 1 — rechargement du groupe dans le terminal courant
newgrp docker

# Option 2 — déconnexion / reconnexion SSH
exit
ssh user@machine
```

---

## 🛠️ Compatibilité

| Élément | Valeur |
|---|---|
| Distribution cible | Debian 13 Trixie |
| Architecture | `amd64` (auto-détectée via `dpkg --print-architecture`) |
| Init system | systemd |
| Docker | CE (Community Edition) — dépôt officiel Docker Inc. |
| Compose | Plugin intégré (`docker compose`) |

> ⚠️ Le script détecte si la distribution n'est pas Trixie et affiche un avertissement, mais n'interrompt pas l'exécution pour autant.

---

## 📄 Licence

Libre d'utilisation et de modification pour tout usage personnel ou professionnel.
