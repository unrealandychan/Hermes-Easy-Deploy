#!/usr/bin/env bash
# azure.sh — Azure wizard, deploy, and management helpers
# Enum values (VALID_AZURE_LOCATIONS, AZURE_LOCATION_LABELS, VALID_AZURE_VM_SIZES,
# AZURE_VM_SIZE_LABELS, API_PROVIDER_*) are defined in lib/enums.sh

# ─── Wizard ─────────────────────────────────────────────────────────────────
azure_wizard() {
  local steps=6
  preflight_check_cloud "azure"

  # Ensure authenticated
  if ! az account show &>/dev/null; then
    warn "No active Azure session. Launching az login..."
    az login
  fi

  # ── Step 1: Subscription / Region ─────────────────────────────────────────
  step_header 1 $steps "Azure Region"
  local sub_name
  sub_name=$(az account show --query name -o tsv 2>/dev/null || echo "unknown")
  warn "Using Azure subscription: ${sub_name}"
  echo ""

  local region_choice
  region_choice=$(choose_one "Select deployment region" "${AZURE_LOCATION_LABELS[@]}")
  REGION="$(echo "$region_choice" | awk '{print $1}')"
  validate_azure_location "$REGION"

  # ── Step 2: VM size ───────────────────────────────────────────────────────
  step_header 2 $steps "VM Size"
  local vm_choice
  vm_choice=$(choose_one "Select VM size" "${AZURE_VM_SIZE_LABELS[@]}")
  local vm_size
  vm_size="$(echo "$vm_choice" | awk '{print $1}')"
  validate_azure_vm_size "$vm_size"

  # ── Step 3: SSH access ────────────────────────────────────────────────────
  step_header 3 $steps "SSH Access"
  local ssh_pub_key_path
  ssh_pub_key_path=$(plain_input "Path to your SSH public key file" "~/.ssh/id_rsa.pub")
  [[ -z "$ssh_pub_key_path" ]] && ssh_pub_key_path="~/.ssh/id_rsa.pub"
  ssh_pub_key_path="${ssh_pub_key_path/#\~/$HOME}"

  if [[ ! -f "$ssh_pub_key_path" ]]; then
    error "Public key not found: ${ssh_pub_key_path}"
    exit 1
  fi
  local ssh_pub_key_content
  ssh_pub_key_content=$(cat "$ssh_pub_key_path")
  # Derive private key path (strip .pub suffix)
  local ssh_private_key="${ssh_pub_key_path%.pub}"

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

  # Globally unique Key Vault name (5–24 chars, alphanumeric + hyphens)
  local kv_name="hermes-kv-$(openssl rand -hex 4)"

  # ── Step 5: Summary ───────────────────────────────────────────────────────
  step_header 5 $steps "Deployment Summary"
  summary_table \
    "Cloud"        "Azure" \
    "Region"       "$REGION" \
    "VM Size"      "$vm_size" \
    "Disk"         "50 GB Premium_LRS (encrypted)" \
    "Resource Grp" "hermes-rg" \
    "Key Vault"    "$kv_name" \
    "Allowed IP"   "$my_ip" \
    "API Keys"     "${key_count} provided"

  # ── Step 6: Confirm ───────────────────────────────────────────────────────
  step_header 6 $steps "Deploy"
  gum confirm "Deploy Hermes Agent to Azure (${REGION})?" || { warn "Aborted."; exit 0; }

  # ── Prepare workspace ─────────────────────────────────────────────────────
  local tf_dir="${HERMES_DEPLOY_HOME}/azure"
  mkdir -p "$tf_dir"
  cp -r "${HERMES_DEPLOY_DIR}/terraform/azure/." "$tf_dir/"
  cp "${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh" "${tf_dir}/bootstrap.sh"
  cp "${HERMES_DEPLOY_DIR}/config/hermes.yaml.tpl" "${tf_dir}/hermes.yaml.tpl"

  cat > "${tf_dir}/terraform.tfvars" <<EOF
location         = "${REGION}"
vm_size          = "${vm_size}"
allowed_ssh_cidr = "${allowed_cidr}"
ssh_public_key   = "${ssh_pub_key_content}"
key_vault_name   = "${kv_name}"
EOF

  cat > "${tf_dir}/secrets.auto.tfvars" <<EOF
openrouter_api_key = "${openrouter_key}"
openai_api_key     = "${openai_key}"
anthropic_api_key  = "${anthropic_key}"
gemini_api_key     = "${gemini_key}"
EOF
  chmod 600 "${tf_dir}/secrets.auto.tfvars"

  config_set "cloud"          "azure"
  config_set "region"         "$REGION"
  config_set "tf_dir"         "$tf_dir"
  config_set "ssh_key_path"   "$ssh_private_key"
  config_set "ssh_user"       "azureuser"
  config_set "key_vault_name" "$kv_name"
  config_set "resource_group" "hermes-rg"

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
    terraform -chdir="$tf_dir" init -upgrade -no-color
  spinner "Planning infrastructure..."      \
    terraform -chdir="$tf_dir" plan -out="${tf_dir}/tfplan" -no-color
  spinner "Applying (this takes ~5 min)..." \
    terraform -chdir="$tf_dir" apply "${tf_dir}/tfplan" -no-color

  local ip instance_id
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null || echo "unknown")
  instance_id=$(terraform -chdir="$tf_dir" output -raw instance_id 2>/dev/null || echo "hermes-instance")

  config_set "public_ip"   "$ip"
  config_set "instance_id" "$instance_id"

  post_deploy_guide "azure" "$ip" "$instance_id" "$REGION" "$ssh_private_key"
}

# ─── Status ─────────────────────────────────────────────────────────────────
azure_status() {
  local tf_dir region ip
  tf_dir=$(config_get "tf_dir")
  region=$(config_get "region")
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null \
       || config_get "public_ip" || echo "unknown")

  local state="unknown"
  if command -v az &>/dev/null; then
    state=$(az vm show \
      --name hermes-instance \
      --resource-group "$(config_get resource_group)" \
      --query "powerState" -o tsv 2>/dev/null || echo "unknown")
  fi

  summary_table \
    "Cloud"     "Azure" \
    "Region"    "$region" \
    "Instance"  "hermes-instance" \
    "Public IP" "$ip" \
    "State"     "$state"
}

# ─── SSH ────────────────────────────────────────────────────────────────────
azure_ssh() {
  local ip ssh_key rg
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"
  ssh_key="${ssh_key/#\~/$HOME}"
  rg=$(config_get "resource_group")

  local method
  method=$(choose_one "Connection method" \
    "Direct SSH  (key pair)" \
    "Azure CLI   (az ssh vm)")

  case "$method" in
    Direct*)
      warn "Connecting to ${ip} as azureuser ..."
      ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "azureuser@${ip}"
      ;;
    Azure*)
      if ! az extension show --name ssh &>/dev/null; then
        spinner "Installing az ssh extension..." \
          az extension add --name ssh --yes
      fi
      warn "Opening az ssh session to hermes-instance ..."
      az ssh vm --name hermes-instance --resource-group "$rg"
      ;;
  esac
}

# ─── Logs ───────────────────────────────────────────────────────────────────
azure_logs() {
  local ip ssh_key
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"
  ssh_key="${ssh_key/#\~/$HOME}"
  warn "Streaming hermes-gateway logs from ${ip} (Ctrl+C to exit)..."
  ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "azureuser@${ip}" \
    "journalctl -u hermes-gateway -f --no-pager"
}

# ─── Secrets ────────────────────────────────────────────────────────────────
azure_secrets() {
  local kv_name
  kv_name=$(config_get "key_vault_name")

  gum style --bold --foreground 212 "Update API Keys in Azure Key Vault: ${kv_name}"
  echo ""

  local provider
  provider=$(choose_one "Which provider's key?" \
    "OpenRouter  (openrouter-api-key)" \
    "OpenAI      (openai-api-key)" \
    "Anthropic   (anthropic-api-key)" \
    "Gemini      (gemini-api-key)")

  local secret_name
  secret_name=$(echo "$provider" | grep -oE '\([^)]+\)' | tr -d '()')
  local new_value
  new_value=$(masked_input "New value for ${secret_name}")

  if [[ -z "$new_value" ]]; then
    warn "No value entered. Skipped."
    return
  fi

  spinner "Updating ${secret_name}..." \
    az keyvault secret set \
      --vault-name "$kv_name" \
      --name "$secret_name" \
      --value "$new_value"

  success "Key updated in Key Vault."
  warn "To apply: hermes-deploy ssh  →  sudo systemctl restart hermes-gateway"
}

# ─── Destroy ────────────────────────────────────────────────────────────────
azure_destroy() {
  local tf_dir
  tf_dir=$(config_get "tf_dir")
  spinner "Destroying Azure infrastructure..." \
    terraform -chdir="$tf_dir" destroy -auto-approve -no-color
  success "All Azure resources destroyed."
}
