#!/usr/bin/env bash
# ui.sh — All TUI helpers for Hermes Agent Cloud (requires gum by Charm)

# ─── ANSI fallbacks (used before gum is confirmed available) ────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Banner ─────────────────────────────────────────────────────────────────
hermes_banner() {
  echo ""
  gum style \
    --border double \
    --border-foreground 212 \
    --padding "1 6" \
    --align center \
    "$(gum style --foreground 212 --bold '⚡  HERMES AGENT CLOUD') $(gum style --foreground 245 "v${HERMES_DEPLOY_VERSION}")" \
    "$(gum style --foreground 245 'Deploy Hermes Agent to AWS · Azure · GCP')"
  echo ""
}

# ─── Step header ────────────────────────────────────────────────────────────
step_header() {
  local step="$1"
  local total="$2"
  local label="$3"
  echo ""
  gum style \
    --foreground 212 \
    --bold \
    "[${step}/${total}]  ${label}"
  echo ""
}

# ─── Spinner ────────────────────────────────────────────────────────────────
# spinner "message" cmd [args...]
# On failure, the full command output is printed for debugging.
spinner() {
  local title="$1"; shift
  local log_file
  log_file=$(mktemp /tmp/hermes-deploy-XXXXXX.log)
  if ! HERMES_LOG="$log_file" gum spin \
    --spinner dot \
    --spinner.foreground 212 \
    --title "  $title" \
    -- bash -c '"$@" >"$HERMES_LOG" 2>&1' _ "$@"; then
    local exit_code
    exit_code=$?
    error "Command failed (exit ${exit_code}). Full output:"
    cat "$log_file" >&2
    rm -f "$log_file"
    return "$exit_code"
  fi
  rm -f "$log_file"
}

# ─── Log levels ─────────────────────────────────────────────────────────────
success() { gum log --level info  "$*"; }
error()   { gum log --level error "$*" >&2; }
warn()    { gum log --level warn  "$*"; }

# ─── Destructive action gate ────────────────────────────────────────────────
confirm_destructive() {
  local msg="$1"
  echo ""
  gum style \
    --foreground 196 \
    --bold \
    "⚠   ${msg}"
  echo ""
  if ! gum confirm --default=false "Are you sure? This cannot be undone."; then
    warn "Aborted."
    exit 0
  fi
}

# ─── Interactive inputs ──────────────────────────────────────────────────────
masked_input() {
  local prompt="$1"
  gum input \
    --password \
    --placeholder "leave blank to skip" \
    --prompt "> " \
    --prompt.foreground 212 \
    --header "$prompt" \
    --header.foreground 245 || true
}

plain_input() {
  local prompt="$1"
  local placeholder="${2:-}"
  gum input \
    --placeholder "$placeholder" \
    --prompt "> " \
    --prompt.foreground 212 \
    --header "$prompt" \
    --header.foreground 245 || true
}

# ─── Single-selection menu ───────────────────────────────────────────────────
# choose_one "prompt" option1 option2 ...
choose_one() {
  local prompt="$1"; shift
  printf '%s\n' "$@" | gum choose \
    --header "$prompt" \
    --header.foreground 245 \
    --cursor.foreground 212 \
    --selected.foreground 212
}

# ─── Summary table ──────────────────────────────────────────────────────────
# summary_table "Key1" "Val1" "Key2" "Val2" ...
summary_table() {
  local lines=""
  while [[ $# -ge 2 ]]; do
    local key="$1"
    local val="$2"
    lines+="$(gum style --foreground 245 --width 16 "$key")$(gum style --foreground 255 "$val")\n"
    shift 2
  done
  echo ""
  gum style \
    --border normal \
    --border-foreground 238 \
    --padding "0 2" \
    "$(printf "%b" "$lines")"
  echo ""
}

# ─── Count non-empty values ─────────────────────────────────────────────────
count_keys() {
  local count=0
  for k in "$@"; do [[ -n "$k" ]] && ((count++)) || true; done
  echo "$count"
}

# ─── Divider ────────────────────────────────────────────────────────────────
divider() {
  local label="${1:-}"
  if [[ -n "$label" ]]; then
    gum style --foreground 212 --bold "  ─── ${label} ───────────────────────────────"
  else
    gum style --foreground 238 "  ──────────────────────────────────────────────"
  fi
}

# ─── Post-deploy access guide ───────────────────────────────────────────────
post_deploy_guide() {
  local cloud="$1"
  local ip="$2"
  local instance_id="$3"
  local region="$4"
  local ssh_key="${5:-~/.ssh/id_rsa}"

  local ssh_user
  case "$cloud" in
    aws)   ssh_user="ubuntu"    ;;
    azure) ssh_user="azureuser" ;;
    gcp)   ssh_user="ubuntu"    ;;
  esac

  local cloud_upper
  cloud_upper="$(echo "$cloud" | tr '[:lower:]' '[:upper:]')"

  echo ""
  gum style \
    --border double \
    --border-foreground 46 \
    --padding "1 4" \
    --bold \
    "$(gum style --foreground 46 '✓  Hermes Agent deployed and installed successfully')"

  echo ""
  summary_table \
    "Cloud"      "${cloud_upper} • ${region}" \
    "Instance"   "${instance_id}" \
    "Public IP"  "${ip}" \
    "Status"     "running"

  # ── How to access ──────────────────────────────────────────────────────
  divider "HOW TO ACCESS YOUR HERMES SERVER"
  echo ""

  gum style --bold --foreground 255 "  1.  Direct SSH (key pair)"
  gum style --foreground 245        "      ssh -i ${ssh_key} ${ssh_user}@${ip}"
  gum style --foreground 245        "      Shortcut: $(gum style --foreground 212 'hermes-agent-cloud ssh')"
  echo ""

  gum style --bold --foreground 255 "  2.  Cloud-native shell  (no open SSH port needed)"
  case "$cloud" in
    aws)
      gum style --foreground 245 "      aws ssm start-session --target ${instance_id} --region ${region}"
      gum style --foreground 245 "      Requires: AWS CLI + Session Manager plugin installed locally"
      ;;
    azure)
      gum style --foreground 245 "      az ssh vm --name hermes-instance --resource-group hermes-rg"
      gum style --foreground 245 "      Requires: Azure CLI + az ssh extension (az extension add --name ssh)"
      ;;
    gcp)
      gum style --foreground 245 "      gcloud compute ssh hermes-instance --zone ${region}"
      gum style --foreground 245 "      Requires: gcloud CLI authenticated to the project"
      ;;
  esac
  echo ""

  gum style --bold --foreground 255 "  3.  Hermes Gateway  (web & API access)"
  gum style --foreground 245        "      http://${ip}:8080"
  gum style --foreground 245        "      Port 8080 is restricted to your current IP only."
  echo ""

  gum style --bold --foreground 255 "  4.  Quick commands"
  gum style --foreground 245 "      $(gum style --foreground 212 'hermes-agent-cloud ssh')       open a shell on the instance"
  gum style --foreground 245 "      $(gum style --foreground 212 'hermes-agent-cloud logs')      stream hermes-gateway logs live"
  gum style --foreground 245 "      $(gum style --foreground 212 'hermes-agent-cloud status')    show instance IP and health"
  gum style --foreground 245 "      $(gum style --foreground 212 'hermes-agent-cloud secrets')   rotate or add API keys"
  gum style --foreground 245 "      $(gum style --foreground 212 'hermes-agent-cloud destroy')   tear it all down"
  echo ""

  # ── Quick verification ─────────────────────────────────────────────────
  divider "VERIFY YOUR DEPLOYMENT"
  echo ""
  gum style --foreground 245 "  a)  Check the systemd gateway service is running"
  gum style --foreground 245 "      hermes-agent-cloud ssh"
  gum style --foreground 245 "      \$ systemctl status hermes-gateway"
  echo ""
  gum style --foreground 245 "  b)  Run a quick health check"
  gum style --foreground 245 "      \$ hermes doctor"
  echo ""
  gum style --foreground 245 "  c)  Open the gateway in your browser"
  gum style --foreground 245 "      http://${ip}:8080"
  echo ""
  gum style --foreground 245 "  d)  View live install log if you need to diagnose issues"
  gum style --foreground 245 "      \$ sudo tail -f /var/log/hermes-bootstrap.log"
  echo ""

  # ── Security notes ─────────────────────────────────────────────────────
  divider "SECURITY NOTES"
  echo ""
  gum style --foreground 245 "  •  SSH (port 22) and gateway (port 8080) are restricted"
  gum style --foreground 245 "     to your current IP only. If your IP changes, re-run:"
  gum style --foreground 245 "     $(gum style --foreground 212 'hermes-agent-cloud deploy') and update the firewall rule."
  echo ""
  gum style --foreground 245 "  •  API keys are stored in ~/.hermes/.env on the VM (chmod 600)."
  gum style --foreground 245 "     They were delivered over SSH and are not stored in Terraform state."
  echo ""
  gum style --foreground 245 "  •  Do NOT open port 8080 to 0.0.0.0/0 unless you add"
  gum style --foreground 245 "     authentication (e.g. a reverse proxy) in front of the gateway."
  echo ""

  # ── Destroy reminder ───────────────────────────────────────────────────
  divider "DESTROY WHEN DONE"
  echo ""
  gum style --foreground 245 "  hermes-agent-cloud destroy"
  gum style --foreground 245 "  You will be asked to confirm before anything is deleted."
  echo ""
}
