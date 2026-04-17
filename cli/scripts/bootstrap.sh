#!/usr/bin/env bash
# bootstrap.sh — Hermes Agent installation and configuration script
#
# Runs over SSH after Terraform provisions the VM.
# Expects ~/.hermes/.env to already exist (written by the CLI via ssh_upload_env).
# Must be run as root (sudo).
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────
HERMES_USER="ubuntu"
HERMES_HOME="/home/$HERMES_USER/.hermes"
HERMES_ENV="$HERMES_HOME/.env"
HERMES_CONFIG="$HERMES_HOME/config.yaml"
LOG_FILE="/var/log/hermes-bootstrap.log"
LOG_TAG="hermes-bootstrap"

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

# ── 3. Install Hermes Agent ──────────────────────────────────────────────────
log "Step 3/4: Installing Hermes Agent"
sudo -u $HERMES_USER bash -c \
  'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'

# Locate the hermes binary (installer may put it in ~/.local/bin or /usr/local/bin)
HERMES_BIN=$(sudo -u $HERMES_USER bash -c \
  'command -v hermes 2>/dev/null || echo /home/ubuntu/.local/bin/hermes')
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
YAML
chown -R $HERMES_USER:$HERMES_USER $HERMES_HOME
log "  Hermes config written to $HERMES_CONFIG"

# ── 4. Register hermes-gateway systemd service ───────────────────────────────
log "Step 4/4: Registering systemd service"
cat > /etc/systemd/system/hermes-gateway.service <<EOF
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
systemctl enable hermes-gateway
systemctl start hermes-gateway
log "  hermes-gateway service started"

log "Bootstrap complete. Check status: journalctl -u hermes-gateway -f"
