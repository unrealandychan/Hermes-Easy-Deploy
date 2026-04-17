#!/usr/bin/env bash
# aws.sh — AWS wizard, deploy, and management helpers
# Enum values (VALID_AWS_REGIONS, AWS_REGION_LABELS, VALID_AWS_INSTANCE_TYPES,
# AWS_INSTANCE_TYPE_LABELS, API_PROVIDER_*) are defined in lib/enums.sh

# ─── Wizard ─────────────────────────────────────────────────────────────────
aws_wizard() {
  local steps=6
  preflight_check_cloud "aws"

  # ── Step 1: Region ────────────────────────────────────────────────────────
  step_header 1 $steps "AWS Region"
  local region_choice
  region_choice=$(choose_one "Select deployment region" "${AWS_REGION_LABELS[@]}")
  REGION="$(echo "$region_choice" | awk '{print $1}')"
  validate_aws_region "$REGION"

  # ── Step 2: Instance size ─────────────────────────────────────────────────
  step_header 2 $steps "Instance Size"
  local instance_choice
  instance_choice=$(choose_one "Select EC2 instance type" "${AWS_INSTANCE_TYPE_LABELS[@]}")
  local instance_type
  instance_type="$(echo "$instance_choice" | awk '{print $1}')"
  validate_aws_instance_type "$instance_type"

  # ── Step 3: SSH access ────────────────────────────────────────────────────
  step_header 3 $steps "SSH Access"
  local key_name
  key_name=$(plain_input "EC2 Key Pair name  (must already exist in region ${REGION})" "my-key-pair")
  if [[ -z "$key_name" ]]; then
    error "EC2 Key Pair name is required."
    exit 1
  fi

  local ssh_key_path
  ssh_key_path=$(plain_input "Path to local private key file" "~/.ssh/id_rsa")
  [[ -z "$ssh_key_path" ]] && ssh_key_path="~/.ssh/id_rsa"

  # Auto-detect deployer IP for security group lockdown
  local my_ip
  my_ip=$(curl -sf --max-time 5 "https://api.ipify.org" \
            || curl -sf --max-time 5 "https://ifconfig.me" \
            || echo "0.0.0.0")
  local allowed_cidr="${my_ip}/32"
  warn "SSH / gateway access will be locked to your current IP: ${my_ip}"

  # ── Step 4: API Keys ──────────────────────────────────────────────────────
  step_header 4 $steps "API Keys  (at least one required)"
  local openrouter_key openai_key anthropic_key gemini_key
  openrouter_key=$(masked_input "OpenRouter API key")
  openai_key=$(masked_input "OpenAI API key")
  anthropic_key=$(masked_input "Anthropic (Claude) API key")
  gemini_key=$(masked_input "Google Gemini API key")

  local key_count
  key_count=$(count_keys "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key")
  if [[ "$key_count" -eq 0 ]]; then
    error "At least one API key is required."
    exit 1
  fi
  success "${key_count} key(s) provided"

  # ── Step 5: Summary ───────────────────────────────────────────────────────
  step_header 5 $steps "Deployment Summary"
  summary_table \
    "Cloud"      "AWS" \
    "Region"     "$REGION" \
    "Instance"   "$instance_type" \
    "Disk"       "50 GB gp3 (encrypted)" \
    "Key Pair"   "$key_name" \
    "Allowed IP" "$my_ip" \
    "API Keys"   "${key_count} provided"

  # ── Step 6: Confirm ───────────────────────────────────────────────────────
  step_header 6 $steps "Deploy"
  gum confirm "Deploy Hermes Agent to AWS (${REGION})?" || { warn "Aborted."; exit 0; }

  # ── Prepare workspace ─────────────────────────────────────────────────────
  local tf_dir="${HERMES_DEPLOY_HOME}/aws"
  mkdir -p "$tf_dir"
  cp -r "${HERMES_DEPLOY_DIR}/terraform/aws/." "$tf_dir/"

  # Non-secret tfvars
  cat > "${tf_dir}/terraform.tfvars" <<EOF
aws_region        = "${REGION}"
instance_type     = "${instance_type}"
key_name          = "${key_name}"
allowed_ssh_cidr  = "${allowed_cidr}"
EOF

  # API key tfvars (auto-loaded by Terraform, kept out of terraform.tfvars)
  cat > "${tf_dir}/secrets.auto.tfvars" <<EOF
openrouter_api_key = "${openrouter_key}"
openai_api_key     = "${openai_key}"
anthropic_api_key  = "${anthropic_key}"
gemini_api_key     = "${gemini_key}"
EOF

  # Persist config
  config_set "cloud"        "aws"
  config_set "region"       "$REGION"
  config_set "tf_dir"       "$tf_dir"
  config_set "ssh_key_path" "$ssh_key_path"
  config_set "ssh_user"     "ubuntu"

  # ── Terraform ─────────────────────────────────────────────────────────────
  echo ""
  if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run — showing plan only, no resources will be created."
    spinner "Initializing Terraform..." \
      terraform -chdir="$tf_dir" init -upgrade -no-color
    terraform -chdir="$tf_dir" plan -no-color
    return
  fi

  spinner "Initializing Terraform..."       \
    terraform -chdir="$tf_dir" init -no-color
  spinner "Applying (this takes ~3 min)..." \
    terraform -chdir="$tf_dir" apply -auto-approve -no-color

  # Capture outputs — grep the state file to avoid multi-line terraform messages
  local ip instance_id
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null)
  ip="${ip//$'\n'/}"
  [[ -z "$ip" ]] && ip="unknown"
  instance_id=$(terraform -chdir="$tf_dir" output -raw instance_id 2>/dev/null)
  instance_id="${instance_id//$'\n'/}"
  [[ -z "$instance_id" ]] && instance_id="unknown"

  config_set "public_ip"   "$ip"
  config_set "instance_id" "$instance_id"

  # ── SSH-based installation ─────────────────────────────────────────────────
  ssh_wait   "$ip" "ubuntu" "$ssh_key_path"
  ssh_upload_env "$ip" "ubuntu" "$ssh_key_path" \
    "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key"
  ssh_install "$ip" "ubuntu" "$ssh_key_path" \
    "${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh"

  post_deploy_guide "aws" "$ip" "$instance_id" "$REGION" "$ssh_key_path"
}

# ─── Status ─────────────────────────────────────────────────────────────────
aws_status() {
  local tf_dir region ip instance_id
  tf_dir=$(config_get "tf_dir")
  region=$(config_get "region")
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null \
       || config_get "public_ip" || echo "unknown")
  instance_id=$(terraform -chdir="$tf_dir" output -raw instance_id 2>/dev/null \
                || config_get "instance_id" || echo "unknown")

  local state="unknown"
  if [[ -n "$instance_id" && "$instance_id" != "unknown" ]]; then
    state=$(aws ec2 describe-instance-status \
      --instance-ids "$instance_id" \
      --region "$region" \
      --query "InstanceStatuses[0].InstanceState.Name" \
      --output text 2>/dev/null || echo "unknown")
  fi

  summary_table \
    "Cloud"      "AWS" \
    "Region"     "$region" \
    "Instance"   "$instance_id" \
    "Public IP"  "$ip" \
    "State"      "$state"
}

# ─── SSH ────────────────────────────────────────────────────────────────────
aws_ssh() {
  local ip instance_id region ssh_key
  ip=$(config_get "public_ip")
  instance_id=$(config_get "instance_id")
  region=$(config_get "region")
  ssh_key=$(config_get "ssh_key_path")

  # Expand tilde
  ssh_key="${ssh_key/#\~/$HOME}"

  local method
  method=$(choose_one "Connection method" \
    "Direct SSH  (key pair)" \
    "AWS SSM Session Manager  (no open port needed)")

  case "$method" in
    Direct*)
      if [[ ! -f "$ssh_key" ]]; then
        error "Private key not found: ${ssh_key}"
        exit 1
      fi
      warn "Connecting to ${ip} as ubuntu ..."
      ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}"
      ;;
    AWS*)
      if ! command -v session-manager-plugin &>/dev/null; then
        warn "AWS Session Manager plugin not found."
        echo "  Install from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
        exit 1
      fi
      warn "Opening SSM session to ${instance_id} ..."
      aws ssm start-session --target "$instance_id" --region "$region"
      ;;
  esac
}

# ─── Logs ───────────────────────────────────────────────────────────────────
aws_logs() {
  local ip ssh_key
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"
  ssh_key="${ssh_key/#\~/$HOME}"
  warn "Streaming hermes-gateway logs from ${ip} (Ctrl+C to exit)..."
  ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}" \
    "journalctl -u hermes-gateway -f --no-pager"
}

# ─── Secrets ────────────────────────────────────────────────────────────────
aws_secrets() {
  local ip ssh_key
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"

  gum style --bold --foreground 212 "Update API Keys on the Hermes instance"
  echo ""

  local provider
  provider=$(choose_one "Which provider's key?" \
    "OpenRouter  (OPENROUTER_API_KEY)" \
    "OpenAI      (OPENAI_API_KEY)" \
    "Anthropic   (ANTHROPIC_API_KEY)" \
    "Gemini      (GEMINI_API_KEY)")

  local var_name
  var_name=$(echo "$provider" | grep -oE '\([^)]+\)' | tr -d '()')
  local new_value
  new_value=$(masked_input "New value for ${var_name}")

  if [[ -z "$new_value" ]]; then
    warn "No value entered. Skipped."
    return
  fi

  ssh_update_key "$ip" "ubuntu" "$ssh_key" "$var_name" "$new_value"
}

# ─── Destroy ────────────────────────────────────────────────────────────────
aws_destroy() {
  local tf_dir
  tf_dir=$(config_get "tf_dir")
  spinner "Destroying AWS infrastructure..." \
    terraform -chdir="$tf_dir" destroy -auto-approve -no-color
  success "All AWS resources destroyed."
}
