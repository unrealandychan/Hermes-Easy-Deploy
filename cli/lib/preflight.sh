#!/usr/bin/env bash
# preflight.sh — Dependency checks for Hermes Agent Cloud

_check_cmd() {
  local name="$1"
  local install_hint="$2"
  if ! command -v "$name" &>/dev/null; then
    echo -e "${RED}✗${RESET}  ${BOLD}${name}${RESET} not found"
    echo    "   ${install_hint}"
    PREFLIGHT_PASS=false
  else
    echo -e "${GREEN}✓${RESET}  ${name} $(command -v "$name")"
  fi
}

preflight_check() {
  local PREFLIGHT_PASS=true

  echo ""
  gum style --bold --foreground 212 "Checking dependencies..."
  echo ""

  _check_cmd "gum" \
    "Install: brew install gum  OR  https://github.com/charmbracelet/gum/releases"
  _check_cmd "terraform" \
    "Install: brew install terraform  OR  https://developer.hashicorp.com/terraform/install"
  _check_cmd "jq" \
    "Install: brew install jq  OR  apt-get install jq"

  if [[ "$PREFLIGHT_PASS" == "false" ]]; then
    echo ""
    error "Missing dependencies above. Install them then re-run hermes-agent-cloud."
    exit 1
  fi
  echo ""
}

preflight_check_cloud() {
  local cloud="$1"
  local PREFLIGHT_PASS=true

  echo ""
  gum style --bold --foreground 212 "Checking ${cloud} CLI..."
  echo ""

  case "$cloud" in
    aws)
      _check_cmd "aws" \
        "Install: brew install awscli  OR  https://aws.amazon.com/cli/"
      if command -v aws &>/dev/null; then
        if ! aws sts get-caller-identity &>/dev/null; then
          warn "AWS credentials not configured. Run: aws configure"
          PREFLIGHT_PASS=false
        else
          echo -e "${GREEN}✓${RESET}  AWS credentials valid ($(aws sts get-caller-identity --query Account --output text 2>/dev/null))"
        fi
      fi
      ;;
    azure)
      _check_cmd "az" \
        "Install: brew install azure-cli  OR  https://docs.microsoft.com/cli/azure/install-azure-cli"
      if command -v az &>/dev/null; then
        if ! az account show &>/dev/null; then
          warn "No active Azure session. Run: az login"
          # Non-fatal — the wizard handles az login
        else
          echo -e "${GREEN}✓${RESET}  Azure session active ($(az account show --query name -o tsv 2>/dev/null))"
        fi
      fi
      ;;
    gcp)
      _check_cmd "gcloud" \
        "Install: brew install --cask google-cloud-sdk  OR  https://cloud.google.com/sdk/docs/install"
      if command -v gcloud &>/dev/null; then
        local active_account
        active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
        if [[ -z "$active_account" ]]; then
          warn "No active GCP session. Run: gcloud auth login"
          # Non-fatal — the wizard handles gcloud auth login
        else
          echo -e "${GREEN}✓${RESET}  GCP session active (${active_account})"
        fi
      fi
      ;;
  esac

  if [[ "$PREFLIGHT_PASS" == "false" ]]; then
    echo ""
    error "Missing cloud CLI. Install and authenticate, then re-run."
    exit 1
  fi
  echo ""
}
