#!/usr/bin/env bash
# gcp.sh — GCP wizard, deploy, and management helpers
# Enum values (VALID_GCP_REGIONS, GCP_REGION_LABELS, VALID_GCP_MACHINE_TYPES,
# GCP_MACHINE_TYPE_LABELS, API_PROVIDER_*) are defined in lib/enums.sh

# ─── Wizard ─────────────────────────────────────────────────────────────────
gcp_wizard() {
  local steps=6
  preflight_check_cloud "gcp"

  # Ensure authenticated
  local active_account
  active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
  if [[ -z "$active_account" ]]; then
    warn "No active GCP session. Launching gcloud auth login..."
    gcloud auth login
    gcloud auth application-default login
  fi

  # ── Step 1: Project & Region ──────────────────────────────────────────────
  step_header 1 $steps "GCP Project & Region"
  local project_id
  project_id=$(gcloud config get-value project 2>/dev/null || echo "")
  if [[ -z "$project_id" ]]; then
    project_id=$(plain_input "GCP Project ID")
    if [[ -z "$project_id" ]]; then
      error "GCP Project ID is required."
      exit 1
    fi
  else
    warn "Using GCP project: ${project_id}"
  fi

  local region_choice
  region_choice=$(choose_one "Select deployment region" "${GCP_REGION_LABELS[@]}")
  REGION="$(echo "$region_choice" | awk '{print $1}')"
  validate_gcp_region "$REGION"
  local zone="${REGION}-a"

  # ── Step 2: Machine type ──────────────────────────────────────────────────
  step_header 2 $steps "Machine Type"
  local machine_choice
  machine_choice=$(choose_one "Select machine type" "${GCP_MACHINE_TYPE_LABELS[@]}")
  local machine_type
  machine_type="$(echo "$machine_choice" | awk '{print $1}')"
  validate_gcp_machine_type "$machine_type"

  # ── Step 3: Network access ────────────────────────────────────────────────
  step_header 3 $steps "Network Access"
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
    "Cloud"        "GCP" \
    "Project"      "$project_id" \
    "Region / Zone" "${REGION} / ${zone}" \
    "Machine"      "$machine_type" \
    "Disk"         "50 GB pd-ssd (encrypted)" \
    "Allowed IP"   "$my_ip" \
    "API Keys"     "${key_count} provided"

  # ── Step 6: Confirm ───────────────────────────────────────────────────────
  step_header 6 $steps "Deploy"
  gum confirm "Deploy Hermes Agent to GCP (${REGION})?" || { warn "Aborted."; exit 0; }

  # ── Prepare workspace ─────────────────────────────────────────────────────
  local tf_dir="${HERMES_DEPLOY_HOME}/gcp"
  mkdir -p "$tf_dir"
  cp -r "${HERMES_DEPLOY_DIR}/terraform/gcp/." "$tf_dir/"

  cat > "${tf_dir}/terraform.tfvars" <<EOF
project_id       = "${project_id}"
region           = "${REGION}"
zone             = "${zone}"
machine_type     = "${machine_type}"
allowed_ssh_cidr = "${allowed_cidr}"
EOF

  config_set "cloud"      "gcp"
  config_set "region"     "$REGION"
  config_set "zone"       "$zone"
  config_set "project_id" "$project_id"
  config_set "tf_dir"     "$tf_dir"
  config_set "ssh_user"   "ubuntu"

  # ── Enable required GCP APIs ────────────────────────────────────────────
  echo ""
  spinner "Enabling GCP Compute API..." bash -c "
    gcloud services enable compute.googleapis.com \
      --project '${project_id}' 2>/dev/null || true
  "

  # ── Terraform ─────────────────────────────────────────────────────────────
  if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run — showing plan only, no resources will be created."
    spinner "Initializing Terraform..." \
      terraform -chdir="$tf_dir" init -upgrade -no-color
    terraform -chdir="$tf_dir" plan -no-color
    return
  fi

  spinner "Initializing Terraform..."       \
    terraform -chdir="$tf_dir" init -upgrade -no-color
  spinner "Planning infrastructure..."      \
    terraform -chdir="$tf_dir" plan -out="${tf_dir}/tfplan" -no-color
  spinner "Applying (this takes ~4 min)..." \
    terraform -chdir="$tf_dir" apply "${tf_dir}/tfplan" -no-color

  local ip
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null || echo "unknown")

  config_set "public_ip"   "$ip"
  config_set "instance_id" "hermes-instance"

  # ── SSH-based installation ─────────────────────────────────────────────────
  local gcp_ssh_key="$HOME/.ssh/google_compute_engine"
  ssh_wait   "$ip" "ubuntu" "$gcp_ssh_key"
  ssh_upload_env "$ip" "ubuntu" "$gcp_ssh_key" \
    "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key"
  ssh_install "$ip" "ubuntu" "$gcp_ssh_key" \
    "${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh"

  post_deploy_guide "gcp" "$ip" "hermes-instance" "$zone" "$gcp_ssh_key"
}

# ─── Status ─────────────────────────────────────────────────────────────────
gcp_status() {
  local tf_dir zone project_id ip
  tf_dir=$(config_get "tf_dir")
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null \
       || config_get "public_ip" || echo "unknown")

  local state="unknown"
  if command -v gcloud &>/dev/null; then
    state=$(gcloud compute instances describe hermes-instance \
      --zone "$zone" \
      --project "$project_id" \
      --format="value(status)" 2>/dev/null || echo "unknown")
  fi

  summary_table \
    "Cloud"     "GCP" \
    "Zone"      "$zone" \
    "Instance"  "hermes-instance" \
    "Public IP" "$ip" \
    "State"     "$state"
}

# ─── SSH ────────────────────────────────────────────────────────────────────
gcp_ssh() {
  local zone project_id ip
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  ip=$(config_get "public_ip")

  local method
  method=$(choose_one "Connection method" \
    "gcloud compute ssh  (recommended)" \
    "Direct SSH          (manual key)")

  case "$method" in
    gcloud*)
      warn "Connecting via gcloud to hermes-instance / ${zone} ..."
      gcloud compute ssh hermes-instance \
        --zone "$zone" \
        --project "$project_id"
      ;;
    Direct*)
      local key="$HOME/.ssh/google_compute_engine"
      warn "Connecting to ${ip} as ubuntu ..."
      ssh -i "$key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}"
      ;;
  esac
}

# ─── Logs ───────────────────────────────────────────────────────────────────
gcp_logs() {
  local zone project_id
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  warn "Streaming hermes-gateway logs (Ctrl+C to exit)..."
  gcloud compute ssh hermes-instance \
    --zone "$zone" \
    --project "$project_id" \
    -- "journalctl -u hermes-gateway -f --no-pager"
}

# ─── Secrets ────────────────────────────────────────────────────────────────
gcp_secrets() {
  local ip
  ip=$(config_get "public_ip")
  local gcp_ssh_key="$HOME/.ssh/google_compute_engine"

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

  ssh_update_key "$ip" "ubuntu" "$gcp_ssh_key" "$var_name" "$new_value"
}

# ─── Destroy ────────────────────────────────────────────────────────────────
gcp_destroy() {
  local tf_dir
  tf_dir=$(config_get "tf_dir")
  spinner "Destroying GCP infrastructure..." \
    terraform -chdir="$tf_dir" destroy -auto-approve -no-color
  success "All GCP resources destroyed."
}
