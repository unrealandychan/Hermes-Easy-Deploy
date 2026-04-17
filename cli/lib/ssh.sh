#!/usr/bin/env bash
# ssh.sh — SSH helpers for post-Terraform installation

# ─── Wait for SSH to become available ───────────────────────────────────────
# ssh_wait <ip> <user> <key_path> [timeout_seconds]
ssh_wait() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local timeout="${4:-300}"
  local elapsed=0
  local interval=10

  # Expand tilde
  key="${key/#\~/$HOME}"

  warn "Waiting for SSH on ${ip} (up to ${timeout}s)..."
  while (( elapsed < timeout )); do
    if ssh -i "$key" \
         -o StrictHostKeyChecking=accept-new \
         -o ConnectTimeout=5 \
         -o BatchMode=yes \
         "${user}@${ip}" exit 0 &>/dev/null; then
      success "SSH is ready on ${ip}"
      return 0
    fi
    sleep "$interval"
    (( elapsed += interval ))
  done

  error "SSH did not become available on ${ip} after ${timeout}s"
  return 1
}

# ─── Upload API keys to ~/.hermes/.env ──────────────────────────────────────
# ssh_upload_env <ip> <user> <key_path> <openrouter> <openai> <anthropic> <gemini>
ssh_upload_env() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local openrouter_key="$4"
  local openai_key="$5"
  local anthropic_key="$6"
  local gemini_key="$7"

  key="${key/#\~/$HOME}"

  # Build .env content — only include lines for non-empty keys
  local env_content=""
  [[ -n "$openrouter_key" ]] && env_content+="OPENROUTER_API_KEY=${openrouter_key}"$'\n'
  [[ -n "$openai_key"     ]] && env_content+="OPENAI_API_KEY=${openai_key}"$'\n'
  [[ -n "$anthropic_key"  ]] && env_content+="ANTHROPIC_API_KEY=${anthropic_key}"$'\n'
  [[ -n "$gemini_key"     ]] && env_content+="GEMINI_API_KEY=${gemini_key}"$'\n'

  warn "Uploading API keys to ${user}@${ip}:~/.hermes/.env ..."
  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${ip}" \
      'mkdir -p ~/.hermes && cat > ~/.hermes/.env && chmod 600 ~/.hermes/.env' \
      <<< "$env_content"

  success "API keys uploaded."
}

# ─── Run bootstrap.sh on the remote VM via SSH ──────────────────────────────
# ssh_install <ip> <user> <key_path> <bootstrap_script_path>
# Output is streamed directly to the terminal so the user sees every step.
ssh_install() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local bootstrap="$4"

  key="${key/#\~/$HOME}"

  echo ""
  gum style --foreground 212 --bold "  ─── Installing Hermes Agent via SSH ────────────────────────"
  warn "Streaming install output from ${ip} (this takes ~3-5 min)..."
  echo ""

  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=15 \
      "${user}@${ip}" \
      'sudo bash -s' < "$bootstrap"

  echo ""
  success "Remote installation complete."
}

# ─── Update a single key in ~/.hermes/.env and restart the gateway ──────────
# ssh_update_key <ip> <user> <key_path> <env_var_name> <new_value>
ssh_update_key() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local var_name="$4"
  local new_value="$5"

  key="${key/#\~/$HOME}"

  warn "Updating ${var_name} on ${user}@${ip} ..."
  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${ip}" \
      "sed -i '/^${var_name}=/d' ~/.hermes/.env && echo '${var_name}=${new_value}' >> ~/.hermes/.env && chmod 600 ~/.hermes/.env && sudo systemctl restart hermes-gateway"

  success "${var_name} updated and hermes-gateway restarted."
}
