#!/usr/bin/env bash
# bootstrap.sh — Hermes Agent installation and configuration script
#
# Runs over SSH after Terraform provisions the VM.
# Expects the profile .env to already exist (written by the CLI via ssh_upload_env).
# Must be run as root (sudo).
#
# Usage: bootstrap.sh [--user <ssh-user>] [--profile <profile-name>] [--web-port <port>] [--api-port <port>]
set -euo pipefail

# ── Argument parsing ────────────────────────────────────────────────────────
HERMES_USER="ubuntu"
HERMES_PROFILE="default"
WEB_PORT="9119"
API_PORT="8080"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)      HERMES_USER="$2";    shift 2 ;;
    --profile)   HERMES_PROFILE="$2"; shift 2 ;;
    --web-port)  WEB_PORT="$2";       shift 2 ;;
    --api-port)  API_PORT="$2";       shift 2 ;;
    *) shift ;;
  esac
done

# ── Constants ──────────────────────────────────────────────────────────────
# Profiles are stored under ~/.hermes-profiles/<name>/
# The "default" profile keeps .env at ~/.hermes/.env for backward compatibility.
HERMES_PROFILES_ROOT="/home/${HERMES_USER}/.hermes-profiles"
if [[ "$HERMES_PROFILE" == "default" ]]; then
  HERMES_HOME="/home/$HERMES_USER/.hermes"
else
  HERMES_HOME="${HERMES_PROFILES_ROOT}/${HERMES_PROFILE}"
fi
HERMES_ENV="$HERMES_HOME/.env"
HERMES_CONFIG="$HERMES_HOME/config.yaml"
SERVICE_NAME="hermes-${HERMES_PROFILE}"
LOG_FILE="/var/log/hermes-bootstrap-${HERMES_PROFILE}.log"
LOG_TAG="hermes-bootstrap[${HERMES_PROFILE}]"

log()  { echo "[$LOG_TAG] $*" | tee -a $LOG_FILE; }
fail() { echo "[$LOG_TAG] ERROR: $*" | tee -a $LOG_FILE >&2; exit 1; }

exec > >(tee -a $LOG_FILE) 2>&1
log "Starting Hermes bootstrap"

[[ -f "$HERMES_ENV" ]] || fail "$HERMES_ENV not found — API keys must be deployed before running bootstrap"

# ── 1. System packages ──────────────────────────────────────────────────────
log "Step 1/4: System packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl jq unzip ca-certificates gnupg lsb-release

# ── 2. Install Docker (Hermes sandbox backend) ───────────────────────────────
log "Step 2/4: Installing Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
fi
usermod -aG docker $HERMES_USER
log "  Docker $(docker --version)"

# ── 3. Install Hermes Agent (always pull latest) ─────────────────────────────
log "Step 3/4: Installing Hermes Agent (latest)"
sudo -u $HERMES_USER bash -c \
  'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'

# Locate the hermes binary (installer may put it in ~/.local/bin or /usr/local/bin)
HERMES_BIN=$(sudo -u "$HERMES_USER" bash -c \
  "command -v hermes 2>/dev/null || echo /home/${HERMES_USER}/.local/bin/hermes")
log "  Hermes binary: $HERMES_BIN"

# Write Hermes config
mkdir -p $HERMES_HOME
cat > $HERMES_CONFIG <<'YAML'
terminal:
  backend: docker
  container_cpu: 1
  container_memory: 5120
  container_disk: 51200
  container_persistent: true

agent:
  max_turns: 90

compression:
  enabled: true
  threshold: 0.50

display:
  tool_progress: all

web:
  enabled: true
  port: ${WEB_PORT}
YAML
chown -R $HERMES_USER:$HERMES_USER $HERMES_HOME
log "  Hermes config written to $HERMES_CONFIG"

# ── 4. Register hermes-gateway systemd service ───────────────────────────────
log "Step 4/4: Registering systemd service (${SERVICE_NAME})"
cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=Hermes Agent Gateway
Documentation=https://hermes-agent.nousresearch.com
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$HERMES_USER
WorkingDirectory=/home/$HERMES_USER
EnvironmentFile=$HERMES_ENV
ExecStart=$HERMES_BIN gateway serve
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"
log "  hermes-gateway service started"

log "Bootstrap complete. Check status: journalctl -u ${SERVICE_NAME} -f"
