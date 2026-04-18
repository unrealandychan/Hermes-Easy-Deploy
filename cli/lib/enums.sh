#!/usr/bin/env bash
# enums.sh — All enumerated values and validation helpers for Hermes Agent Cloud
#
# HOW TO EXTEND
# ─────────────
# Add a cloud    : append to VALID_CLOUDS + CLOUD_DISPLAY_LABELS, create lib/<cloud>.sh,
#                  add case branches in hermes-deploy and scripts/bootstrap.sh
# Add a region   : append to VALID_<CLOUD>_REGIONS + <CLOUD>_REGION_LABELS (same index)
# Add an LLM key : append to API_PROVIDER_ORDER, add key→value entries in the four
#                  API_PROVIDER_* arrays, update scripts/bootstrap.sh pull_* functions

# ════════════════════════════════════════════════════════════════════════════
#  Cloud providers
# ════════════════════════════════════════════════════════════════════════════
VALID_CLOUDS=("aws" "azure" "gcp")

# Human-readable labels — index-aligned with VALID_CLOUDS
CLOUD_DISPLAY_LABELS=(
  "AWS    — Amazon Web Services"
  "Azure  — Microsoft Azure"
  "GCP    — Google Cloud Platform"
)

# ════════════════════════════════════════════════════════════════════════════
#  API key providers
# ════════════════════════════════════════════════════════════════════════════
# Ordered list — controls wizard display order.  Add new providers here.
API_PROVIDER_ORDER=("openrouter" "openai" "anthropic" "gemini")

# Provider key → human-readable label
declare -A API_PROVIDER_LABELS=(
  [openrouter]="OpenRouter"
  [openai]="OpenAI"
  [anthropic]="Anthropic (Claude)"
  [gemini]="Google Gemini"
)

# Provider key → env var written into ~/.hermes/.env
declare -A API_PROVIDER_ENV_VARS=(
  [openrouter]="OPENROUTER_API_KEY"
  [openai]="OPENAI_API_KEY"
  [anthropic]="ANTHROPIC_API_KEY"
  [gemini]="GEMINI_API_KEY"
)

# Provider key → AWS SSM Parameter Store path
declare -A API_PROVIDER_AWS_SSM=(
  [openrouter]="/hermes/openrouter_api_key"
  [openai]="/hermes/openai_api_key"
  [anthropic]="/hermes/anthropic_api_key"
  [gemini]="/hermes/gemini_api_key"
)

# Provider key → Azure Key Vault secret name
declare -A API_PROVIDER_AZURE_KV=(
  [openrouter]="openrouter-api-key"
  [openai]="openai-api-key"
  [anthropic]="anthropic-api-key"
  [gemini]="gemini-api-key"
)

# Provider key → GCP Secret Manager secret name
declare -A API_PROVIDER_GCP_SECRET=(
  [openrouter]="hermes-openrouter-api-key"
  [openai]="hermes-openai-api-key"
  [anthropic]="hermes-anthropic-api-key"
  [gemini]="hermes-gemini-api-key"
)

# ════════════════════════════════════════════════════════════════════════════
#  AWS
# ════════════════════════════════════════════════════════════════════════════
# Raw region identifiers used for validation and tfvars
VALID_AWS_REGIONS=(
  "ap-east-1"
  "us-east-1"
  "us-west-2"
  "eu-west-1"
  "eu-central-1"
  "ap-southeast-1"
  "ap-northeast-1"
  "ap-south-1"
)

# Human-readable labels shown in the wizard — index-aligned with VALID_AWS_REGIONS
AWS_REGION_LABELS=(
  "ap-east-1      (Hong Kong)"
  "us-east-1      (N. Virginia)"
  "us-west-2      (Oregon)"
  "eu-west-1      (Ireland)"
  "eu-central-1   (Frankfurt)"
  "ap-southeast-1 (Singapore)"
  "ap-northeast-1 (Tokyo)"
  "ap-south-1     (Mumbai)"
)

VALID_AWS_INSTANCE_TYPES=("t3.large" "t3.xlarge" "t3.2xlarge")

AWS_INSTANCE_TYPE_LABELS=(
  "t3.large    — 2 vCPU  8 GB   (Recommended)"
  "t3.xlarge   — 4 vCPU  16 GB  (Larger)"
  "t3.2xlarge  — 8 vCPU  32 GB  (High performance)"
)

# ════════════════════════════════════════════════════════════════════════════
#  Azure
# ════════════════════════════════════════════════════════════════════════════
VALID_AZURE_LOCATIONS=(
  "eastasia"
  "eastus"
  "westus2"
  "westeurope"
  "northeurope"
  "southeastasia"
  "japaneast"
)

AZURE_LOCATION_LABELS=(
  "eastasia       (East Asia — Hong Kong)"
  "eastus         (East US)"
  "westus2        (West US 2)"
  "westeurope     (West Europe)"
  "northeurope    (North Europe)"
  "southeastasia  (Southeast Asia)"
  "japaneast      (Japan East)"
)

VALID_AZURE_VM_SIZES=(
  "Standard_D2s_v3"
  "Standard_D4s_v3"
  "Standard_D8s_v3"
)

AZURE_VM_SIZE_LABELS=(
  "Standard_D2s_v3  — 2 vCPU  8 GB   (Recommended)"
  "Standard_D4s_v3  — 4 vCPU  16 GB  (Larger)"
  "Standard_D8s_v3  — 8 vCPU  32 GB  (High performance)"
)

# ════════════════════════════════════════════════════════════════════════════
#  GCP
# ════════════════════════════════════════════════════════════════════════════
VALID_GCP_REGIONS=(
  "asia-east2"
  "us-central1"
  "us-east1"
  "europe-west1"
  "europe-west4"
  "asia-southeast1"
  "asia-northeast1"
)

GCP_REGION_LABELS=(
  "asia-east2         (Hong Kong)"
  "us-central1        (Iowa)"
  "us-east1           (South Carolina)"
  "europe-west1       (Belgium)"
  "europe-west4       (Netherlands)"
  "asia-southeast1    (Singapore)"
  "asia-northeast1    (Tokyo)"
)

VALID_GCP_MACHINE_TYPES=(
  "e2-standard-2"
  "e2-standard-4"
  "e2-standard-8"
)

GCP_MACHINE_TYPE_LABELS=(
  "e2-standard-2  — 2 vCPU  8 GB   (Recommended)"
  "e2-standard-4  — 4 vCPU  16 GB  (Larger)"
  "e2-standard-8  — 8 vCPU  32 GB  (High performance)"
)

# ════════════════════════════════════════════════════════════════════════════
#  Generic helpers  (bash 3.2+ compatible — no namerefs)
# ════════════════════════════════════════════════════════════════════════════

# enum_contains "value" "${ARRAY[@]}"
# Returns 0 if value is present in the remaining arguments, 1 otherwise.
# Usage: enum_contains "$CLOUD" "${VALID_CLOUDS[@]}"
enum_contains() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# enum_values_str "separator" val1 val2 ...
# Joins args with separator into a single string.
# Usage: enum_values_str " | " "${VALID_CLOUDS[@]}"
enum_values_str() {
  local sep="$1"; shift
  local result="" item
  for item in "$@"; do
    result="${result}${sep}${item}"
  done
  # Strip leading separator
  echo "${result:${#sep}}"
}

# ════════════════════════════════════════════════════════════════════════════
#  Typed validation functions  (call these at wizard input points)
# ════════════════════════════════════════════════════════════════════════════

validate_cloud() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_CLOUDS[@]}"; then
    error "Invalid cloud provider: '${value}'"
    echo "  Valid values: $(enum_values_str ' | ' "${VALID_CLOUDS[@]}")" >&2
    exit 1
  fi
}

# Regions and sizes: warn-only (non-fatal) so custom values still pass through
validate_aws_region() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_AWS_REGIONS[@]}"; then
    warn "Region '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_AWS_REGIONS[@]}")"
  fi
}

validate_aws_instance_type() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_AWS_INSTANCE_TYPES[@]}"; then
    warn "Instance type '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_AWS_INSTANCE_TYPES[@]}")"
  fi
}

validate_azure_location() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_AZURE_LOCATIONS[@]}"; then
    warn "Location '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_AZURE_LOCATIONS[@]}")"
  fi
}

validate_azure_vm_size() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_AZURE_VM_SIZES[@]}"; then
    warn "VM size '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_AZURE_VM_SIZES[@]}")"
  fi
}

validate_gcp_region() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_GCP_REGIONS[@]}"; then
    warn "Region '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_GCP_REGIONS[@]}")"
  fi
}

validate_gcp_machine_type() {
  local value="$1"
  if ! enum_contains "$value" "${VALID_GCP_MACHINE_TYPES[@]}"; then
    warn "Machine type '${value}' is not in the known list — proceeding anyway."
    warn "Known: $(enum_values_str ', ' "${VALID_GCP_MACHINE_TYPES[@]}")"
  fi
}
