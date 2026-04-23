#!/usr/bin/env bash
# profile.sh — Multi-profile management for Hermes Agent Cloud
#
# Each profile is an isolated Hermes Agent instance with its own:
#   - API keys  : ~/.hermes-profiles/<name>/.env
#   - Config    : ~/.hermes-profiles/<name>/config.yaml
#   - Port pair : web (9119+N) and API gateway (8080+N)
#   - systemd   : hermes-<name>.service
#
# The "default" profile is backward-compatible with v1.x single-instance deploys.

PROFILES_DIR="${HOME}/.hermes-profiles"
ACTIVE_PROFILE_FILE="${HERMES_DEPLOY_HOME}/active_profile"

# ── Port allocation ──────────────────────────────────────────────────────────
# default → web=9119, api=8080
# Profile slot N (0-based) → web=9119+N, api=8080+N
profile_web_port()  { local slot="${1:-0}"; echo $(( 9119 + slot )); }
profile_api_port()  { local slot="${1:-0}"; echo $(( 8080 + slot )); }

profile_slot() {
  local name="$1"
  [[ "$name" == "default" ]] && { echo 0; return; }
  local slots_file="${HERMES_DEPLOY_HOME}/profile_slots"
  touch "$slots_file"
  # Find existing slot
  local existing
  existing=$(grep "^${name}=" "$slots_file" 2>/dev/null | cut -d= -f2 || true)
  if [[ -n "$existing" ]]; then
    echo "$existing"
    return
  fi
  # Allocate next available slot (1-based for non-default)
  local max=0
  while IFS='=' read -r _ slot; do
    (( slot > max )) && max=$slot
  done < "$slots_file"
  local next=$(( max + 1 ))
  echo "${name}=${next}" >> "$slots_file"
  echo "$next"
}

# ── Active profile ───────────────────────────────────────────────────────────
profile_get_active() {
  if [[ -f "$ACTIVE_PROFILE_FILE" ]]; then
    cat "$ACTIVE_PROFILE_FILE"
  else
    echo "default"
  fi
}

profile_set_active() {
  local name="$1"
  mkdir -p "$HERMES_DEPLOY_HOME"
  echo "$name" > "$ACTIVE_PROFILE_FILE"
}

# ── Profile directory ────────────────────────────────────────────────────────
profile_dir() {
  local name="${1:-default}"
  echo "${PROFILES_DIR}/${name}"
}

profile_exists() {
  local name="$1"
  [[ -d "${PROFILES_DIR}/${name}" ]]
}

profile_list_names() {
  if [[ ! -d "$PROFILES_DIR" ]]; then
    echo "default"
    return
  fi
  ls -1 "$PROFILES_DIR" 2>/dev/null || echo "default"
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_profile() {
  local subcmd="${1:-}"
  shift || true

  case "$subcmd" in
    list)    profile_cmd_list   "$@" ;;
    use)     profile_cmd_use    "$@" ;;
    create)  profile_cmd_create "$@" ;;
    remove)  profile_cmd_remove "$@" ;;
    show)    profile_cmd_show   "$@" ;;
    ""|help) profile_cmd_help        ;;
    *)
      error "Unknown profile subcommand: $subcmd"
      profile_cmd_help
      exit 1
      ;;
  esac
}

profile_cmd_help() {
  echo ""
  gum style --foreground 212 --bold "USAGE"
  echo "  hermes-agent-cloud profile <subcommand>"
  echo ""
  gum style --foreground 212 --bold "SUBCOMMANDS"
  printf "  %-10s %s\n" "list"   "List all profiles and their status"
  printf "  %-10s %s\n" "use"    "Switch the active profile"
  printf "  %-10s %s\n" "create" "Create a new named profile (prompts for API keys)"
  printf "  %-10s %s\n" "remove" "Delete a profile and its config"
  printf "  %-10s %s\n" "show"   "Show details of a profile"
  echo ""
  gum style --foreground 212 --bold "EXAMPLES"
  echo "  hermes-agent-cloud profile list"
  echo "  hermes-agent-cloud profile create work"
  echo "  hermes-agent-cloud profile use work"
  echo "  hermes-agent-cloud profile remove work"
  echo ""
}

profile_cmd_list() {
  local active
  active=$(profile_get_active)

  echo ""
  gum style --bold --foreground 212 "Hermes Agent Profiles"
  echo ""
  printf "  %-16s %-8s %-12s %-12s %s\n" "NAME" "STATUS" "WEB PORT" "API PORT" "CONFIG"
  printf "  %-16s %-8s %-12s %-12s %s\n" "────────────────" "────────" "────────────" "────────────" "──────"

  local found=false
  while IFS= read -r name; do
    found=true
    local slot
    slot=$(profile_slot "$name")
    local web_port api_port
    web_port=$(profile_web_port "$slot")
    api_port=$(profile_api_port "$slot")

    local dir
    dir=$(profile_dir "$name")
    local cfg_status="no config"
    [[ -f "${dir}/config.yaml" ]] && cfg_status="configured"
    [[ -f "${dir}/.env" ]] && cfg_status="configured+keys"

    local marker=""
    [[ "$name" == "$active" ]] && marker=" ★"

    printf "  %-16s %-8s %-12s %-12s %s%s\n" \
      "$name" "$cfg_status" ":$web_port" ":$api_port" "$dir" "$marker"
  done < <(profile_list_names)

  if [[ "$found" == "false" ]]; then
    echo "  (no profiles yet — run: hermes-agent-cloud profile create <name>)"
  fi

  echo ""
  echo "  ★ = active profile"
  echo ""
}

profile_cmd_use() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    error "Usage: hermes-agent-cloud profile use <name>"
    exit 1
  fi

  if ! profile_exists "$name" && [[ "$name" != "default" ]]; then
    error "Profile '${name}' does not exist. Run: hermes-agent-cloud profile create ${name}"
    exit 1
  fi

  profile_set_active "$name"
  success "Active profile set to: ${name}"

  local slot
  slot=$(profile_slot "$name")
  local web_port api_port
  web_port=$(profile_web_port "$slot")
  api_port=$(profile_api_port "$slot")
  echo ""
  echo "  Web dashboard : http://<your-ip>:${web_port}"
  echo "  API gateway   : http://<your-ip>:${api_port}"
  echo ""
}

profile_cmd_create() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(gum input --placeholder "profile name (e.g. work, personal)" --prompt "Profile name: ")
  fi

  if [[ -z "$name" ]]; then
    error "Profile name is required."
    exit 1
  fi

  # Validate name: lowercase, alphanumeric + hyphens
  if ! [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    error "Profile name must be lowercase alphanumeric with hyphens (e.g. 'work', 'my-profile')."
    exit 1
  fi

  if profile_exists "$name"; then
    warn "Profile '${name}' already exists."
    gum confirm "Overwrite its API keys?" || exit 0
  fi

  local dir
  dir=$(profile_dir "$name")
  mkdir -p "$dir"

  local slot
  slot=$(profile_slot "$name")
  local web_port api_port
  web_port=$(profile_web_port "$slot")
  api_port=$(profile_api_port "$slot")

  echo ""
  gum style --bold --foreground 212 "Creating profile: ${name}"
  echo ""
  warn "Ports: web=${web_port}, api=${api_port}"
  echo ""

  # ── Collect API keys ──────────────────────────────────────────────────────
  gum style --bold "API Keys  (at least one required)"
  echo ""
  local openrouter_key openai_key anthropic_key gemini_key
  openrouter_key=$(masked_input "OpenRouter API key")
  openai_key=$(masked_input "OpenAI API key")
  anthropic_key=$(masked_input "Anthropic (Claude) API key")
  gemini_key=$(masked_input "Google Gemini API key")

  local key_count
  key_count=$(count_keys "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key")
  if [[ "$key_count" -eq 0 ]]; then
    error "At least one API key is required."
    rm -rf "$dir"
    exit 1
  fi

  # ── Write .env ────────────────────────────────────────────────────────────
  local env_file="${dir}/.env"
  : > "$env_file"
  [[ -n "$openrouter_key" ]] && echo "OPENROUTER_API_KEY=${openrouter_key}" >> "$env_file"
  [[ -n "$openai_key"     ]] && echo "OPENAI_API_KEY=${openai_key}"         >> "$env_file"
  [[ -n "$anthropic_key"  ]] && echo "ANTHROPIC_API_KEY=${anthropic_key}"   >> "$env_file"
  [[ -n "$gemini_key"     ]] && echo "GEMINI_API_KEY=${gemini_key}"         >> "$env_file"
  chmod 600 "$env_file"

  # ── Write config.yaml ─────────────────────────────────────────────────────
  cat > "${dir}/config.yaml" <<YAML
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
  port: ${web_port}
YAML

  success "Profile '${name}' created at ${dir}"
  echo ""
  echo "  To deploy this profile:  hermes-agent-cloud profile use ${name} && hermes-agent-cloud deploy"
  echo "  To list all profiles:    hermes-agent-cloud profile list"
  echo ""
}

profile_cmd_remove() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    error "Usage: hermes-agent-cloud profile remove <name>"
    exit 1
  fi

  if [[ "$name" == "default" ]]; then
    error "Cannot remove the 'default' profile."
    exit 1
  fi

  if ! profile_exists "$name"; then
    error "Profile '${name}' does not exist."
    exit 1
  fi

  gum confirm "Remove profile '${name}' and all its config? This cannot be undone." || exit 0

  rm -rf "$(profile_dir "$name")"

  # Remove from slots file
  local slots_file="${HERMES_DEPLOY_HOME}/profile_slots"
  if [[ -f "$slots_file" ]]; then
    sed -i.bak "/^${name}=/d" "$slots_file"
    rm -f "${slots_file}.bak"
  fi

  # Reset active if it was this profile
  local active
  active=$(profile_get_active)
  if [[ "$active" == "$name" ]]; then
    profile_set_active "default"
    warn "Active profile reset to 'default'."
  fi

  success "Profile '${name}' removed."
}

profile_cmd_show() {
  local name="${1:-$(profile_get_active)}"
  local dir
  dir=$(profile_dir "$name")

  echo ""
  gum style --bold --foreground 212 "Profile: ${name}"
  echo ""

  local slot
  slot=$(profile_slot "$name")
  printf "  %-14s %s\n" "Directory:"  "$dir"
  printf "  %-14s %s\n" "Web port:"   "$(profile_web_port "$slot")"
  printf "  %-14s %s\n" "API port:"   "$(profile_api_port "$slot")"

  if [[ -f "${dir}/.env" ]]; then
    echo ""
    gum style --bold "API Keys:"
    while IFS='=' read -r key _; do
      [[ -z "$key" || "$key" == \#* ]] && continue
      printf "  ✓  %s\n" "$key"
    done < "${dir}/.env"
  else
    warn "No .env file — run: hermes-agent-cloud profile create ${name}"
  fi

  if [[ -f "${dir}/config.yaml" ]]; then
    echo ""
    gum style --bold "config.yaml:"
    sed 's/^/    /' "${dir}/config.yaml"
  fi
  echo ""
}
