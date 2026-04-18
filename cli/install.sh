#!/usr/bin/env bash
# install.sh — One-line installer for Hermes Agent Cloud
# Usage: curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
#    or: bash install.sh  (from a local clone)
set -euo pipefail

HERMES_DEPLOY_VERSION="1.0.1"
INSTALL_BIN="/usr/local/bin"
INSTALL_LIB="/usr/local/lib/hermes-agent-cloud"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

OS="$(uname -s)"
ARCH="$(uname -m)"

banner() {
  echo ""
  echo -e "${BOLD}Hermes Agent Cloud installer — v${HERMES_DEPLOY_VERSION}${RESET}"
  echo -e "${DIM}─────────────────────────────────────────${RESET}"
  echo ""
}

info()    { echo -e "  ${BOLD}→${RESET}  $*"; }
ok()      { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
die()     { echo -e "  ${RED}✗${RESET}  $*" >&2; exit 1; }

require_sudo() {
  if [[ "$EUID" -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    warn "Some steps require sudo — you may be prompted for your password."
  fi
}

# ── Ensure Bash 4+ for CLI runtime ─────────────────────────────────────────
install_bash() {
  local bash_major
  bash_major="$(bash -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null || echo 0)"

  if [[ "$bash_major" -ge 4 ]]; then
    ok "bash $(bash --version | head -1 | sed 's/^GNU bash, version //') already installed"
    return
  fi

  info "Installing Bash 4+ (required by Hermes Agent Cloud)..."

  case "$OS" in
    Darwin)
      command -v brew &>/dev/null || die "Homebrew is required to install Bash 4+ on macOS. Install from https://brew.sh"
      brew install bash
      ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq bash
      elif command -v yum &>/dev/null; then
        sudo yum install -y bash
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y bash
      else
        die "Could not install Bash automatically. Please install Bash 4+ manually."
      fi
      ;;
    *)
      die "Unsupported OS. Install Bash 4+ manually."
      ;;
  esac

  ok "bash 4+ installed"
}

# ── Install gum ─────────────────────────────────────────────────────────────
install_gum() {
  if command -v gum &>/dev/null; then
    ok "gum $(gum --version 2>/dev/null || echo '') already installed"
    return
  fi

  info "Installing gum (Charm TUI library)..."
  local GUM_VERSION="0.14.5"

  case "$OS" in
    Darwin)
      brew install gum
      ;;
    Linux)
      local arch_label
      case "$ARCH" in
        x86_64)  arch_label="amd64" ;;
        aarch64|arm64) arch_label="arm64" ;;
        *) die "Unsupported architecture: $ARCH. Install gum manually: https://github.com/charmbracelet/gum/releases" ;;
      esac

      # Try package manager first
      if command -v apt-get &>/dev/null; then
        # Charm apt repo
        curl -fsSL https://repo.charm.sh/apt/gpg.key \
          | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/charm.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/trusted.gpg.d/charm.gpg] https://repo.charm.sh/apt/ * *" \
          | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq gum
      else
        # Direct binary download
        local deb="gum_${GUM_VERSION}_linux_${arch_label}.tar.gz"
        curl -fsSLo /tmp/gum.tar.gz \
          "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_${arch_label}.tar.gz"
        tar -xzf /tmp/gum.tar.gz -C /tmp gum
        sudo mv /tmp/gum "$INSTALL_BIN/gum"
        sudo chmod +x "$INSTALL_BIN/gum"
        rm -f /tmp/gum.tar.gz
      fi
      ;;
    *)
      die "Unsupported OS: $OS. Install gum manually: https://github.com/charmbracelet/gum/releases"
      ;;
  esac
  ok "gum installed"
}

# ── Install Terraform ────────────────────────────────────────────────────────
install_terraform() {
  if command -v terraform &>/dev/null; then
    ok "terraform $(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || terraform version | head -1) already installed"
    return
  fi

  info "Installing Terraform..."
  local TF_VERSION="1.8.5"

  case "$OS" in
    Darwin)
      brew tap hashicorp/tap 2>/dev/null || true
      brew install hashicorp/tap/terraform
      ;;
    Linux)
      local arch_label
      case "$ARCH" in
        x86_64)  arch_label="amd64" ;;
        aarch64|arm64) arch_label="arm64" ;;
        *) die "Unsupported architecture: $ARCH" ;;
      esac
      local zip_file="terraform_${TF_VERSION}_linux_${arch_label}.zip"
      curl -fsSLo /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TF_VERSION}/${zip_file}"
      unzip -qqo /tmp/terraform.zip terraform -d /tmp
      sudo mv /tmp/terraform "$INSTALL_BIN/terraform"
      sudo chmod +x "$INSTALL_BIN/terraform"
      rm -f /tmp/terraform.zip
      ;;
    *)
      die "Unsupported OS: $OS. Install Terraform manually: https://developer.hashicorp.com/terraform/install"
      ;;
  esac
  ok "Terraform installed"
}

# ── Install jq ──────────────────────────────────────────────────────────────
install_jq() {
  if command -v jq &>/dev/null; then
    ok "jq $(jq --version) already installed"
    return
  fi

  info "Installing jq..."
  case "$OS" in
    Darwin) brew install jq ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq jq
      elif command -v yum &>/dev/null; then
        sudo yum install -y jq
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y jq
      else
        die "Could not install jq automatically. Please install manually."
      fi
      ;;
    *) die "Unsupported OS. Install jq manually." ;;
  esac
  ok "jq installed"
}

# ── Install Hermes Agent Cloud ──────────────────────────────────────────────────
install_hermes_deploy() {
  info "Installing Hermes Agent Cloud v${HERMES_DEPLOY_VERSION}..."

  local src_dir=""
  local main_bin=""
  local candidate_dir=""

  is_modern_cli_entrypoint() {
    local bin_path="$1"
    [[ -f "$bin_path" ]] || return 1

    # New entrypoint must handle both Bash 4+ gating and symlink-safe directory resolution.
    grep -q "BASH_VERSINFO\[0\]" "$bin_path" \
      && grep -q "resolve_script_dir" "$bin_path"
  }

  # If this script is running from a local clone, use that
  local script_dir
  local script_source="${BASH_SOURCE[0]:-}"
  if [[ -n "$script_source" && "$script_source" != "bash" && "$script_source" != "-bash" ]]; then
    script_dir="$(cd "$(dirname "$script_source")" 2>/dev/null && pwd || echo "")"
  else
    script_dir=""
  fi

  if [[ -n "$script_dir" ]]; then
    for candidate_dir in "$script_dir" "$script_dir/cli"; do
      if [[ -f "$candidate_dir/hermes-deploy" ]]; then
        src_dir="$candidate_dir"
        main_bin="hermes-deploy"
        break
      elif [[ -f "$candidate_dir/hermes-agent-cloud" ]]; then
        src_dir="$candidate_dir"
        main_bin="hermes-agent-cloud"
        break
      fi
    done
  fi

  if [[ -n "$src_dir" && -n "$main_bin" ]]; then
    info "Using local source: $src_dir"
  else
    # Download from GitHub releases
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    local archive_url="https://github.com/unrealandychan/Hermes-Agent-Cloud/archive/refs/tags/v${HERMES_DEPLOY_VERSION}.tar.gz"
    info "Downloading from ${archive_url}..."
    curl -fsSL "$archive_url" | tar -xz -C "$tmp_dir" --strip-components=1

    for candidate_dir in "$tmp_dir/cli" "$tmp_dir"; do
      if [[ -f "$candidate_dir/hermes-deploy" ]]; then
        src_dir="$candidate_dir"
        main_bin="hermes-deploy"
        break
      elif [[ -f "$candidate_dir/hermes-agent-cloud" ]]; then
        src_dir="$candidate_dir"
        main_bin="hermes-agent-cloud"
        break
      fi
    done

    if [[ -n "$main_bin" ]] && ! is_modern_cli_entrypoint "$src_dir/$main_bin"; then
      warn "Tagged archive contains an outdated CLI entrypoint; switching to latest main branch payload."
      src_dir=""
      main_bin=""
    fi

    if [[ -z "$main_bin" ]]; then
      local main_archive_url="https://github.com/unrealandychan/Hermes-Agent-Cloud/archive/refs/heads/main.tar.gz"
      info "Tagged archive did not contain a usable CLI; retrying from ${main_archive_url}..."

      local tmp_main_dir
      tmp_main_dir=$(mktemp -d)
      trap "rm -rf $tmp_dir $tmp_main_dir" EXIT

      curl -fsSL "$main_archive_url" | tar -xz -C "$tmp_main_dir" --strip-components=1

      for candidate_dir in "$tmp_main_dir/cli" "$tmp_main_dir"; do
        if [[ -f "$candidate_dir/hermes-deploy" ]]; then
          src_dir="$candidate_dir"
          main_bin="hermes-deploy"
          break
        elif [[ -f "$candidate_dir/hermes-agent-cloud" ]]; then
          src_dir="$candidate_dir"
          main_bin="hermes-agent-cloud"
          break
        fi
      done
    fi
  fi

  if [[ -z "$main_bin" ]]; then
    die "Could not find CLI executable in source (expected hermes-deploy or hermes-agent-cloud)."
  fi

  # Install to /usr/local/lib/hermes-agent-cloud
  sudo rm -rf "$INSTALL_LIB"
  sudo mkdir -p "$INSTALL_LIB"
  sudo cp -r "$src_dir/." "$INSTALL_LIB/"
  sudo chmod +x "$INSTALL_LIB/$main_bin"
  sudo find "$INSTALL_LIB/lib" -name "*.sh" -exec chmod +x {} \;
  sudo find "$INSTALL_LIB/scripts" -name "*.sh" -exec chmod +x {} \;

  # Symlink the main binary into PATH
  sudo ln -sf "$INSTALL_LIB/$main_bin" "$INSTALL_BIN/hermes-deploy"
  sudo ln -sf "$INSTALL_LIB/$main_bin" "$INSTALL_BIN/hermes-agent-cloud"

  ok "Hermes Agent Cloud installed → $INSTALL_BIN/hermes-deploy"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  banner
  require_sudo

  install_bash
  install_jq
  install_gum
  install_terraform
  install_hermes_deploy

  echo ""
  echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
  echo ""
  echo -e "  ${BOLD}Get started:${RESET}"
  echo "    hermes-deploy                    # launch the wizard"
  echo "    hermes-deploy --help             # show all commands"
  echo "    hermes-deploy version            # confirm version"
  echo "    hermes-agent-cloud               # new command"
  echo ""
}

main "$@"
