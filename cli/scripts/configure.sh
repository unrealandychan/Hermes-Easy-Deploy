#!/usr/bin/env bash
# configure.sh — Post-deploy verification helper
# Run this inside the deployed instance after SSH-ing in.
# Usage:  bash ~/.hermes-agent-cloud/configure.sh

set -euo pipefail

HERMES_HOME="$HOME/.hermes"
HERMES_ENV="$HERMES_HOME/.env"

# ── Colours ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "   ${GREEN}✓${RESET}  $*"; }
fail() { echo -e "   ${RED}✗${RESET}  $*"; }
warn() { echo -e "   ${YELLOW}⚠${RESET}  $*"; }

div() {
  echo ""
  echo -e "${BOLD}$*${RESET}"
  echo "   ──────────────────────────────────"
}

echo ""
echo -e "${BOLD}══════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Hermes Agent — Post-Deploy Verification ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════${RESET}"

# ── 1. Hermes binary ───────────────────────────────────────────────────────
div "1.  Hermes binary"
if command -v hermes &>/dev/null; then
  local_ver=$(hermes --version 2>/dev/null || echo "(version unknown)")
  ok "hermes found: $(command -v hermes)  $local_ver"
else
  fail "hermes not found in PATH"
  warn "Try: source ~/.bashrc  OR  export PATH=\$PATH:\$HOME/.local/bin"
fi

# ── 2. API keys (.hermes/.env) ─────────────────────────────────────────────
div "2.  API keys ($HERMES_ENV)"
if [[ -f "$HERMES_ENV" ]]; then
  local_count=0
  while IFS='=' read -r key _; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    ok "$key is set"
    ((local_count++))
  done < "$HERMES_ENV"
  [[ $local_count -eq 0 ]] && fail "File exists but no keys found inside"
else
  fail "$HERMES_ENV not found"
  warn "The bootstrap script may still be running. Check: sudo tail -f /var/log/hermes-bootstrap.log"
fi

# ── 3. Hermes config ───────────────────────────────────────────────────────
div "3.  Hermes config"
HERMES_CONFIG="$HERMES_HOME/config.yaml"
if [[ -f "$HERMES_CONFIG" ]]; then
  ok "config.yaml found"
  if grep -q "backend: docker" "$HERMES_CONFIG"; then
    ok "terminal.backend = docker (sandboxed)"
  else
    warn "terminal.backend is not 'docker' — check $HERMES_CONFIG"
  fi
else
  fail "config.yaml not found at $HERMES_CONFIG"
fi

# ── 4. Docker ──────────────────────────────────────────────────────────────
div "4.  Docker (sandbox backend)"
if command -v docker &>/dev/null; then
  ok "docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
  if docker info &>/dev/null; then
    ok "Docker daemon is running"
  else
    fail "Docker daemon is not running"
    warn "Try: sudo systemctl start docker"
  fi
  if groups | grep -q docker; then
    ok "Current user is in the docker group"
  else
    warn "Current user is NOT in the docker group. Run: sudo usermod -aG docker \$USER  then re-login"
  fi
else
  fail "docker not found"
fi

# ── 5. systemd service ─────────────────────────────────────────────────────
div "5.  hermes-gateway service"
if systemctl is-active --quiet hermes-gateway 2>/dev/null; then
  ok "hermes-gateway is running"
  systemctl status hermes-gateway --no-pager -l 2>/dev/null \
    | grep -E "Active:|Main PID:" \
    | sed 's/^/       /'
else
  fail "hermes-gateway is NOT running"
  warn "Start it:    sudo systemctl start hermes-gateway"
  warn "View logs:   journalctl -u hermes-gateway -n 50 --no-pager"
fi

# ── 6. hermes doctor ───────────────────────────────────────────────────────
div "6.  hermes doctor"
if command -v hermes &>/dev/null; then
  hermes doctor 2>&1 | sed 's/^/   /' || true
else
  fail "skipped (hermes not in PATH)"
fi

# ── 7. Gateway reachability ────────────────────────────────────────────────
div "7.  Gateway reachability (localhost:8080)"
if curl -sf --max-time 5 http://localhost:8080 &>/dev/null \
   || curl -sf --max-time 5 http://localhost:8080/health &>/dev/null; then
  ok "Gateway responded on :8080"
else
  warn "Gateway did not respond on :8080"
  warn "It may still be starting up — wait 30 s and retry"
  warn "Or check: journalctl -u hermes-gateway -n 30 --no-pager"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${RESET}"
echo ""
