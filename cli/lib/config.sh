#!/usr/bin/env bash
# config.sh — Persist and read Hermes-Agent-Cloud configuration

CONFIG_FILE="${HERMES_DEPLOY_HOME}/config"

# Load saved config — sets CLOUD and REGION globals without sourcing the file
config_load() {
  if [[ -f "$CONFIG_FILE" ]]; then
    [[ -z "${CLOUD:-}"  ]] && CLOUD="$(config_get cloud 2>/dev/null || true)"
    [[ -z "${REGION:-}" ]] && REGION="$(config_get region 2>/dev/null || true)"
  fi
}

# Read a single key from the config file
config_get() {
  local key="$1"
  if [[ ! -f "$CONFIG_FILE" ]]; then return 0; fi
  grep "^${key}=" "$CONFIG_FILE" 2>/dev/null \
    | head -1 \
    | cut -d'=' -f2- \
    | sed 's/^"\(.*\)"$/\1/'
}

# Write / overwrite a key=value pair in the config file
config_set() {
  local key="$1"
  # Strip all newlines from the value so sed patterns are never broken
  local value="${2//$'\n'/}"
  mkdir -p "${HERMES_DEPLOY_HOME}"
  touch "$CONFIG_FILE"

  if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
    # Replace in-place (macOS-compatible)
    sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
  else
    echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
  fi
}

# Remove a key from the config file
config_unset() {
  local key="$1"
  if [[ -f "$CONFIG_FILE" ]]; then
    sed -i.bak "/^${key}=/d" "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
  fi
}

# Print the current config for debugging
config_dump() {
  if [[ -f "$CONFIG_FILE" ]]; then
    cat "$CONFIG_FILE"
  else
    echo "(no config saved yet)"
  fi
}
