# Release Notes

All notable changes to `Hermes-Easy-Deploy` are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

_Changes staged for the next release will appear here._

---

## [1.0.1] — 2026-04-17

### Overview

Replaces the cloud-init / secret-store installation approach with a direct
SSH-based flow. Users now see every installation line printed live in their
terminal. Cloud secret stores (AWS SSM Parameter Store, Azure Key Vault, GCP
Secret Manager) are no longer required.

### Changed

#### Installation flow
- **SSH-based install** — after `terraform apply` the CLI waits for SSH,
  uploads API keys directly to `~/.hermes/.env` (chmod 600) over the SSH
  tunnel, then streams `scripts/bootstrap.sh` execution in real-time so
  users see every step as it happens.
- No more silent background `cloud-init` failures; all output is visible in
  the terminal during deployment.

#### `scripts/bootstrap.sh`
- Removed Terraform `templatefile` variable placeholders (`${HERMES_CLOUD}`,
  `${AWS_REGION}`, `${SSM_PREFIX}`, `${AZURE_KV_NAME}`, `${GCP_PROJECT}`).
- Removed Step 2 (cloud CLI installation: AWS CLI, Azure CLI).
- Removed Step 3 (secret fetch from SSM / Key Vault / Secret Manager).
- Script now expects `~/.hermes/.env` to already exist (uploaded by the CLI).
- Renumbered to 4 steps: system packages → Docker → Hermes Agent → systemd
  service.
- Log file unchanged: `/var/log/hermes-bootstrap.log`.

#### New `lib/ssh.sh`
Four reusable SSH helpers called after every `terraform apply`:
- `ssh_wait` — retry loop (up to 5 min) until SSH is ready.
- `ssh_upload_env` — pipes API keys to `~/.hermes/.env` via stdin (values
  never embedded in the remote command string).
- `ssh_install` — runs `bootstrap.sh` via `sudo bash -s` with live terminal
  output (no spinner wrapper).
- `ssh_update_key` — updates a single key in `.env` via stdin + remote
  `read`, then restarts `hermes-gateway`.

#### Terraform stacks — removed cloud secret stores
| Stack | Removed |
|---|---|
| `terraform/aws/` | `ssm.tf` deleted; SSM read IAM policy removed; `user_data` + `lifecycle.ignore_changes` removed from `aws_instance`; four API key variables removed |
| `terraform/azure/` | `keyvault.tf` deleted; `custom_data`, `lifecycle`, Managed Identity removed from VM; `key_vault_name` + four API key variables removed |
| `terraform/gcp/` | `secretmanager.tf` deleted; `startup-script` metadata, `service_account` block, and `google_service_account` resource removed; four API key variables removed |

Note: AWS IAM role and `AmazonSSMManagedInstanceCore` attachment are **kept**
so AWS Session Manager shells still work without an open SSH port.

#### `lib/aws.sh` / `lib/azure.sh` / `lib/gcp.sh`
- Removed `secrets.auto.tfvars` generation.
- Each cloud wizard now calls `ssh_wait → ssh_upload_env → ssh_install` after
  `terraform apply`.
- `*_secrets` commands rewritten: update `~/.hermes/.env` on the instance via
  `ssh_update_key` instead of cloud vault CLIs.
- `lib/azure.sh`: removed `key_vault_name` generation and
  `config_set "key_vault_name"`.
- `lib/gcp.sh`: removed `gcloud services enable secretmanager.googleapis.com`.

#### `lib/ui.sh` — `post_deploy_guide`
- Removed cloud-init / cloud-vault security notes.
- Replaced first-boot checklist with direct verification steps (install
  already completed during deploy; no wait needed).
- Updated success banner to say "deployed and installed successfully".

### Security

- API keys are delivered exclusively over the already-established SSH tunnel.
- Keys are written to `~/.hermes/.env` (chmod 600) on the VM and are **not**
  stored in Terraform state, cloud vaults, or instance metadata.
- Remote command strings never contain key values — all secrets pass through
  `stdin` pipes.

---

## [1.0.0] — 2026-04-14

### Overview

Initial release. Full wizard-first CLI to deploy Hermes Agent to AWS, Azure, and GCP
with a single command through a beautiful `gum`-powered TUI.

### Added

#### Core CLI (`Hermes-Easy-Deploy`)
- Subcommand router: `deploy`, `status`, `ssh`, `logs`, `secrets`, `destroy`, `version`, `help`
- Global flags: `--cloud`, `--region`, `--dry-run`, `--no-color`, `--help`
- `--cloud` flag validated against `VALID_CLOUDS` enum on parse — exits with a clear error on invalid value
- Config persistence in `~/.Hermes-Easy-Deploy/config` (key=value store, no external dependencies)

#### TUI (`lib/ui.sh` + Charm `gum`)
- `hermes_banner` — double-bordered Hermes ASCII header with version
- `step_header N total label` — numbered step indicators for multi-step wizards
- `spinner "msg" cmd...` — dot-style spinner wrapping any long-running command
- `masked_input` / `plain_input` — styled `gum input` wrappers
- `choose_one` — `gum choose` single-selection menu used for all enum fields
- `summary_table` — bordered key-value table displayed before every deployment
- `confirm_destructive` — `gum confirm` gate (default=false) on all destroy operations
- `post_deploy_guide` — detailed live access guide printed after deploy with:
  - Instance ID, IP, and cloud-specific access commands
  - Direct SSH, cloud-native shell (SSM / az ssh / gcloud), gateway URL
  - First-boot checklist with exact commands
  - Per-cloud security notes
  - Destroy reminder

#### Enum system (`lib/enums.sh`)
- Single source of truth for all valid values: cloud providers, regions, instance types, LLM providers
- Parallel `*_LABELS` arrays (human-readable wizard display) aligned by index with `VALID_*` arrays
- `API_PROVIDER_ORDER`, `API_PROVIDER_LABELS`, `API_PROVIDER_ENV_VARS`, `API_PROVIDER_AWS_SSM`,
  `API_PROVIDER_AZURE_KV`, `API_PROVIDER_GCP_SECRET` associative arrays for all four LLM providers
- Generic helpers (bash 3.2+ compatible):
  - `enum_contains "value" "${ARRAY[@]}"` — membership test
  - `enum_values_str "sep" "${ARRAY[@]}"` — joins values with separator
- Typed validation functions per resource: `validate_cloud` (fatal), `validate_aws_region`,
  `validate_aws_instance_type`, `validate_azure_location`, `validate_azure_vm_size`,
  `validate_gcp_region`, `validate_gcp_machine_type` (warning-only for non-fatal paths)

#### LLM Provider support
- **OpenRouter** (`OPENROUTER_API_KEY`)
- **OpenAI** (`OPENAI_API_KEY`)
- **Anthropic / Claude** (`ANTHROPIC_API_KEY`)
- **Google Gemini** (`GEMINI_API_KEY`)
- At least one key required; wizard validates before proceeding
- All keys optional individually; only provided keys are created in the cloud vault
- `Hermes-Easy-Deploy secrets` command to rotate any key without re-deploying

#### AWS provider (`lib/aws.sh` + `terraform/aws/`)
- 6-step wizard: region → instance type → SSH key pair → API keys → summary → confirm
- Terraform stack: EC2 (`t3.large` default), Ubuntu 24.04 LTS, 50 GB gp3 encrypted root
- IAM: instance role with `AmazonSSMManagedInstanceCore` + inline SSM read policy for `/hermes/*`
- SSM Parameter Store: four `SecureString` params, count-conditional (only created when key provided)
- Security group: SSH (22) + gateway (8080) restricted to deployer IP; all egress open
- `aws_ssh`: choice of direct SSH or AWS SSM Session Manager
- `aws_logs`: SSH → `journalctl -u hermes-gateway -f`
- `aws_secrets`: `aws ssm put-parameter --overwrite` per provider
- `aws_destroy`: `terraform destroy -auto-approve`

#### Azure provider (`lib/azure.sh` + `terraform/azure/`)
- 6-step wizard: region → VM size → SSH public key → API keys → summary → confirm
- Terraform stack: `Standard_D2s_v3`, Ubuntu 24.04, 50 GB Premium_LRS encrypted disk
- System-assigned Managed Identity for Key Vault access (no credentials on instance)
- Azure Key Vault (standard SKU, soft-delete 7 days) with deployer access policy + VM accessor policy
- NSG: rules for SSH + gateway from deployer IP; VNet + Public IP (static, Standard SKU)
- `az ssh` extension auto-installed if missing on `Hermes-Easy-Deploy ssh`
- `azure_secrets`: `az keyvault secret set`

#### GCP provider (`lib/gcp.sh` + `terraform/gcp/`)
- 6-step wizard: project + region → machine type → API keys → summary → confirm
- Auto-enables `compute.googleapis.com` and `secretmanager.googleapis.com` before apply
- Terraform stack: `e2-standard-2`, Ubuntu 24.04, 50 GB pd-ssd, dedicated service account
- Secret Manager: `for_each` over active providers, IAM `secretAccessor` binding per secret
- Firewall: separate rules for SSH and gateway, both restricted to deployer IP, tagged `hermes-agent`
- `gcp_ssh`: choice of `gcloud compute ssh` or direct SSH
- `gcp_secrets`: `gcloud secrets versions add` via stdin piping

#### Bootstrap script (`scripts/bootstrap.sh`)
- Terraform `templatefile` — cloud identity injected at plan time via `${HERMES_CLOUD}` etc.
- Steps: system packages → cloud CLI install (if needed) → secret fetch → Docker install → Hermes install → systemd service registration
- Per-cloud secret-fetch strategies using only IAM-native APIs (no credentials hardcoded):
  - AWS: `aws ssm get-parameter --with-decryption`
  - Azure: IMDS Managed Identity token → Key Vault REST API
  - GCP: Metadata server OAuth token → Secret Manager REST API
- Writes all present keys to `~ubuntu/.hermes/.env` (mode 600)
- Registers `hermes-gateway.service` with `Restart=on-failure` and `EnvironmentFile`
- Full log at `/var/log/hermes-bootstrap.log`

#### Post-deploy verification (`scripts/configure.sh`)
- 7-point health check: hermes binary, `.env` keys, `config.yaml`, Docker, systemd service,
  `hermes doctor`, gateway reachability on `:8080`
- Color-coded pass/fail/warn output; actionable fix hints on every failure

#### Installer (`install.sh`)
- Detects macOS (brew) vs Linux (apt / binary download)
- Installs `gum` (Charm apt repo on Debian/Ubuntu, binary on others, brew on macOS)
- Installs `terraform` (HashiCorp releases)
- Installs `jq`
- Copies project to `/usr/local/lib/Hermes-Easy-Deploy`, symlinks binary to `/usr/local/bin`
- Works from local clone or remote archive download

### Security

- API keys stored in cloud vault (SSM / Key Vault / Secret Manager); superseded in v1.0.1 by SSH-based delivery
- `secrets.auto.tfvars` is `chmod 600` and gitignored (removed in v1.0.1)
- All inbound ports restricted to deployer IP at deploy time
- IAM roles follow least-privilege principle (read-only on secrets, SSM core for management only)
- Hermes runs in a Docker container sandbox (no direct host access from agent tools)

---

## Upgrade Guide

### From scratch (first install)

Follow the [Installation section in README.md](./README.md#installation).

### Future minor / patch upgrades (1.x.x)

```bash
curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Easy-Deploy/main/cli/install.sh | bash
```

Re-running the installer overwrites the CLI files only. Existing `~/.Hermes-Easy-Deploy/` state
(config, Terraform state) is preserved.

### Breaking changes

None in 1.0.0 (initial release).

---

## Roadmap

Items under consideration for future releases:

- `Hermes-Easy-Deploy update` — pull latest Hermes Agent version on the running instance
- Remote Terraform state backend support (S3 / Azure Storage / GCS)
- `Hermes-Easy-Deploy firewall --update-ip` — update security rules when deployer IP changes
- VPC/subnet selection for AWS (currently uses default VPC)
- Multi-instance support (name flag to manage several deployments per cloud)
- DigitalOcean and Hetzner provider support
- Shell completions (`bash`, `zsh`, `fish`)
