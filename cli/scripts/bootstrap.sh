#!/usr/bin/env bash
# bootstrap.sh — Hermes Agent installation and configuration script
#
# This file is used as a Terraform templatefile. Variable placeholders in
# ${UPPER_CASE} are substituted at terraform plan/apply time.
# All regular bash variables use $lower_case (no braces) to avoid collision.
#
# Runs as: EC2 user_data (AWS) | custom_data (Azure) | startup-script (GCP)
set -euo pipefail

# ── Terraform-injected values (substituted at plan time) ───────────────────
HERMES_CLOUD="${HERMES_CLOUD}"
AWS_REGION="${AWS_REGION}"
SSM_PREFIX="${SSM_PREFIX}"
AZURE_KV_NAME="${AZURE_KV_NAME}"
GCP_PROJECT="${GCP_PROJECT}"

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
log "Starting Hermes bootstrap on cloud=$HERMES_CLOUD"

# ── 1. System packages ──────────────────────────────────────────────────────
log "Step 1/6: System packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl jq unzip ca-certificates gnupg lsb-release

# ── 2. Cloud-specific secret-fetch tool ─────────────────────────────────────
log "Step 2/6: Cloud CLI for secret fetch"

if [[ "$HERMES_CLOUD" == "aws" ]]; then
  if ! command -v aws &>/dev/null; then
    log "Installing AWS CLI v2..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install --update
    rm -rf /tmp/awscliv2.zip /tmp/aws
  fi
fi

if [[ "$HERMES_CLOUD" == "azure" ]]; then
  if ! command -v az &>/dev/null; then
    log "Installing Azure CLI..."
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg
    echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/azure-cli.list
    apt-get update -qq
    apt-get install -y -qq azure-cli
  fi
fi

# GCP — we use the metadata server REST API directly (no gcloud needed on instance)

# ── 3. Pull secrets from cloud secret store ─────────────────────────────────
log "Step 3/6: Fetching API keys"
mkdir -p $HERMES_HOME
chown $HERMES_USER:$HERMES_USER $HERMES_HOME
> $HERMES_ENV

# ── AWS: SSM Parameter Store ────────────────────────────────────────────────
pull_ssm() {
  local name="$1"
  local env_var="$2"
  local value
  value=$(aws ssm get-parameter \
    --name "$name" \
    --with-decryption \
    --region $AWS_REGION \
    --query "Parameter.Value" \
    --output text 2>/dev/null) || value=""
  if [[ -n "$value" ]]; then
    echo "$env_var=$value" >> $HERMES_ENV
    log "  Loaded $env_var from SSM ($name)"
  fi
}

# ── Azure: Key Vault via IMDS Managed Identity token ────────────────────────
pull_keyvault() {
  local secret_name="$1"
  local env_var="$2"
  local token value
  # Obtain a bearer token from the Azure IMDS using the VM's Managed Identity
  token=$(curl -sf \
    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" \
    -H "Metadata:true" | jq -r '.access_token // empty') || token=""
  if [[ -z "$token" ]]; then
    log "  WARN: Could not get Managed Identity token for $secret_name"
    return
  fi
  value=$(curl -sf \
    "https://$AZURE_KV_NAME.vault.azure.net/secrets/$secret_name?api-version=7.4" \
    -H "Authorization: Bearer $token" | jq -r '.value // empty') || value=""
  if [[ -n "$value" ]]; then
    echo "$env_var=$value" >> $HERMES_ENV
    log "  Loaded $env_var from Key Vault ($secret_name)"
  fi
}

# ── GCP: Secret Manager via metadata server OAuth token ─────────────────────
pull_gcp_secret() {
  local secret_name="$1"
  local env_var="$2"
  local token value_b64 value
  token=$(curl -sf \
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
    -H "Metadata-Flavor: Google" | jq -r '.access_token // empty') || token=""
  if [[ -z "$token" ]]; then
    log "  WARN: Could not get Service Account token for $secret_name"
    return
  fi
  value_b64=$(curl -sf \
    "https://secretmanager.googleapis.com/v1/projects/$GCP_PROJECT/secrets/$secret_name/versions/latest:access" \
    -H "Authorization: Bearer $token" | jq -r '.payload.data // empty') || value_b64=""
  if [[ -n "$value_b64" ]]; then
    value=$(echo "$value_b64" | base64 -d)
    echo "$env_var=$value" >> $HERMES_ENV
    log "  Loaded $env_var from Secret Manager ($secret_name)"
  fi
}

case "$HERMES_CLOUD" in
  aws)
    pull_ssm "$SSM_PREFIX/openrouter_api_key" "OPENROUTER_API_KEY"
    pull_ssm "$SSM_PREFIX/openai_api_key"     "OPENAI_API_KEY"
    pull_ssm "$SSM_PREFIX/anthropic_api_key"  "ANTHROPIC_API_KEY"
    pull_ssm "$SSM_PREFIX/gemini_api_key"     "GEMINI_API_KEY"
    ;;
  azure)
    pull_keyvault "openrouter-api-key" "OPENROUTER_API_KEY"
    pull_keyvault "openai-api-key"     "OPENAI_API_KEY"
    pull_keyvault "anthropic-api-key"  "ANTHROPIC_API_KEY"
    pull_keyvault "gemini-api-key"     "GEMINI_API_KEY"
    ;;
  gcp)
    pull_gcp_secret "hermes-openrouter-api-key" "OPENROUTER_API_KEY"
    pull_gcp_secret "hermes-openai-api-key"     "OPENAI_API_KEY"
    pull_gcp_secret "hermes-anthropic-api-key"  "ANTHROPIC_API_KEY"
    pull_gcp_secret "hermes-gemini-api-key"     "GEMINI_API_KEY"
    ;;
  *)
    fail "Unknown HERMES_CLOUD value: $HERMES_CLOUD"
    ;;
esac

chown $HERMES_USER:$HERMES_USER $HERMES_ENV
chmod 600 $HERMES_ENV
log "  $(wc -l < $HERMES_ENV) key(s) written to $HERMES_ENV"

# ── 4. Install Docker (Hermes sandbox backend) ───────────────────────────────
log "Step 4/6: Installing Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
fi
usermod -aG docker $HERMES_USER
log "  Docker $(docker --version)"

# ── 5. Install Hermes Agent ──────────────────────────────────────────────────
log "Step 5/6: Installing Hermes Agent"
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

# ── 6. Register hermes-gateway systemd service ───────────────────────────────
log "Step 6/6: Registering systemd service"
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
