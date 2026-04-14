# hermes-deploy

> Beautiful wizard-first CLI to deploy **Hermes Agent** to AWS, Azure, or GCP — in one command.

Built with [Charm's `gum`](https://github.com/charmbracelet/gum) for a fully interactive TUI. Infrastructure managed by bundled Terraform templates. Zero vendor lock-in, zero container registry required.

---

## Features

- **Interactive wizard** — step-by-step prompts for every option; flags can skip any step for scripted use
- **Three clouds** — AWS (EC2), Azure (VM), GCP (Compute Engine) with dedicated Terraform stacks per provider
- **Four LLM providers** — OpenRouter, OpenAI, Anthropic (Claude), Google Gemini; supply any combination
- **Zero secrets in infrastructure code** — keys stored exclusively in AWS SSM, Azure Key Vault, or GCP Secret Manager; pulled at boot via IAM/Managed Identity
- **Sandboxed execution** — Hermes runs in Docker with CPU/RAM/disk limits out of the box
- **Auto-start on reboot** — `hermes-gateway` registered as a `systemd` service
- **Post-deploy access guide** — printed live after every deployment with real IPs and instance IDs
- **Extensible** — new clouds, regions, and LLM providers added by editing `lib/enums.sh` only

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| `bash` | ≥ 4.3 | `brew install bash` (macOS ships 3.2) |
| `gum` | any | `brew install gum` |
| `terraform` | ≥ 1.5 | `brew install terraform` |
| `jq` | any | `brew install jq` |
| Cloud CLI | — | see **Cloud CLIs** below |

### Cloud CLIs

| Cloud | CLI | Install |
|---|---|---|
| AWS | `aws` + Session Manager plugin | `brew install awscli` |
| Azure | `az` | `brew install azure-cli` |
| GCP | `gcloud` | `brew install --cask google-cloud-sdk` |

You only need the CLI for the cloud you are deploying to.

---

## Installation

### One-liner (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_ORG/hermes-deploy/main/install.sh | bash
```

`install.sh` will:
1. Install `gum`, `terraform`, and `jq` if missing (via `brew` on macOS, apt/binary on Linux)
2. Copy the CLI to `/usr/local/lib/hermes-deploy`
3. Symlink `hermes-deploy` into `/usr/local/bin`

### Manual (from source)

```bash
git clone https://github.com/YOUR_ORG/hermes-deploy.git
cd hermes-deploy
bash install.sh
```

### Verify

```bash
hermes-deploy version
# hermes-deploy v1.0.0
```

---

## Quick Start

```bash
hermes-deploy            # launches the full interactive wizard
```

That's it. The wizard walks you through cloud selection → region → instance size → API keys → confirmation → deploy.

---

## Commands

| Command | Description |
|---|---|
| `hermes-deploy` | Launch the full wizard (default when no command given) |
| `hermes-deploy deploy` | Deploy Hermes Agent (wizard fills any missing flags) |
| `hermes-deploy status` | Show instance IP, state, and resource IDs |
| `hermes-deploy ssh` | Open a shell on the deployed instance |
| `hermes-deploy logs` | Stream live `hermes-gateway` logs |
| `hermes-deploy secrets` | Rotate or add API keys in the cloud vault |
| `hermes-deploy destroy` | Tear down all resources (gated by confirmation prompt) |
| `hermes-deploy version` | Print CLI version |
| `hermes-deploy help` | Show usage |

### Flags

| Flag | Description |
|---|---|
| `--cloud aws\|azure\|gcp` | Target cloud (validated against known values) |
| `--region REGION` | Cloud region (e.g. `ap-east-1`) |
| `--dry-run` | Run `terraform plan` only, no resources created |
| `--no-color` | Disable color output |
| `--help` | Show help |

---

## Wizard Walkthrough

```
$ hermes-deploy

╔══════════════════════════════════════╗
║   ⚡  HERMES DEPLOY  v1.0.0          ║
║   Deploy Hermes Agent to AWS · Azure · GCP ║
╚══════════════════════════════════════╝

[1/6]  Cloud provider
  ❯ AWS   — Amazon Web Services
    Azure — Microsoft Azure
    GCP   — Google Cloud Platform

[2/6]  AWS Region
  ❯ ap-east-1      (Hong Kong)
    us-east-1      (N. Virginia)
    ...

[3/6]  Instance Size
  ❯ t3.large    — 2 vCPU  8 GB   (Recommended)
    t3.xlarge   — 4 vCPU  16 GB

[4/6]  SSH Access
  EC2 Key Pair name: my-key-pair
  Path to private key: ~/.ssh/id_rsa
  ⚠  Restricting access to your IP: 1.2.3.4

[5/6]  API Keys  (at least one required)
  OpenRouter API key   ░░░░░  (skip ↵)
  OpenAI API key       ••••••••••••••
  Anthropic (Claude)   ░░░░░  (skip ↵)
  Google Gemini        ░░░░░  (skip ↵)
  ✓ 1 key provided

[6/6]  Summary
  ┌─────────────────────────────┐
  │ Cloud      AWS              │
  │ Region     ap-east-1        │
  │ Instance   t3.large         │
  │ Disk       50 GB gp3        │
  │ Allowed IP 1.2.3.4          │
  │ API Keys   1 provided       │
  └─────────────────────────────┘

  Deploy Hermes Agent to AWS (ap-east-1)? › Yes

  ⠸  Initializing Terraform...
  ⠸  Planning infrastructure...
  ⠸  Applying (this takes ~3 min)...

╔══════════════════════════════════════╗
║  ✓  Hermes Agent deployed            ║
╚══════════════════════════════════════╝

  [full access guide printed here — SSH, SSM, gateway URL, checklist, security notes]
```

---

## API Key Providers

At least one key is required. All others are optional. Keys are never stored on disk in plaintext — they go directly into the cloud secret store and are fetched by the instance at boot via IAM role / Managed Identity / Service Account.

| Provider | Environment variable | Notes |
|---|---|---|
| **OpenRouter** | `OPENROUTER_API_KEY` | Routes to many models |
| **OpenAI** | `OPENAI_API_KEY` | GPT-5.4, GPT-5.2, etc. |
| **Anthropic (Claude)** | `ANTHROPIC_API_KEY` | Claude 4.x |
| **Google Gemini** | `GEMINI_API_KEY` | Gemini 2.5 / 3.0 |

Update keys at any time without re-deploying:

```bash
hermes-deploy secrets
# then restart on the instance: sudo systemctl restart hermes-gateway
```

---

## Security Model

- **Firewall / NSG / Security Group**: SSH (22) and gateway (8080) are restricted to your current IP only. The ports are **not** open to the public internet.
- **Secrets**: API keys are stored as encrypted secrets in the cloud vault (SSM SecureString / Key Vault / Secret Manager). They are never present in Terraform state, `user_data`, or `custom_data`.
- **IAM least-privilege**: The instance role/identity is granted only `GetParameter` (AWS), `Get/List` secret (Azure), or `secretAccessor` (GCP) — nothing else.
- **`secrets.auto.tfvars`**: Local file created during deploy, `chmod 600`, never committed. Delete it after deployment if desired.
- **Docker sandbox**: Hermes terminal backend runs in a container with 1 vCPU / 5 GB RAM / 50 GB disk limits.

---

## Extending hermes-deploy

The project is designed so that adding a new cloud, region, instance type, or LLM provider requires editing **one file** (`lib/enums.sh`) plus wiring up the execution logic.

### Add a new cloud provider

1. **`lib/enums.sh`** — append to `VALID_CLOUDS` and `CLOUD_DISPLAY_LABELS`
2. **`lib/<cloud>.sh`** — create following the pattern of `lib/aws.sh`
3. **`hermes-deploy`** — add a `source lib/<cloud>.sh` line and a `case` branch in every command function
4. **`terraform/<cloud>/`** — create the Terraform stack
5. **`scripts/bootstrap.sh`** — add a `case` branch for secret-pull logic

### Add a new LLM provider

1. **`lib/enums.sh`** — append the provider key to `API_PROVIDER_ORDER` and add entries in the four `API_PROVIDER_*` associative arrays
2. **`scripts/bootstrap.sh`** — add a `pull_*` call in the cloud-specific `case` block
3. The Terraform SSM/Key Vault/Secret Manager resources are count-conditional — they'll pick up new variables automatically if you add a matching `variable` block

### Add a new region or instance type

1. **`lib/enums.sh`** — append to the relevant `VALID_*` array and the parallel `*_LABELS` array (same index)
2. That's it — the wizard and validation pick it up immediately

---

## Post-Deploy Access

After a successful deploy the CLI prints a full access guide. Quick reference:

| Cloud | SSH | Shell (no open port) | Gateway |
|---|---|---|---|
| AWS | `ssh -i key.pem ubuntu@<IP>` | `aws ssm start-session --target <ID>` | `http://<IP>:8080` |
| Azure | `ssh azureuser@<IP>` | `az ssh vm --name hermes-instance --resource-group hermes-rg` | `http://<IP>:8080` |
| GCP | `ssh ubuntu@<IP>` | `gcloud compute ssh hermes-instance --zone <zone>` | `http://<IP>:8080` |

Shortcut for all:

```bash
hermes-deploy ssh     # auto-detects cloud and method
hermes-deploy logs    # stream hermes-gateway logs live
```

### First-boot checklist (~2 min after deploy)

```bash
hermes-deploy ssh

# inside the instance:
hermes doctor                            # verify installation
systemctl status hermes-gateway          # confirm service running
cat ~/.hermes/.env                       # confirm keys loaded
curl -sf http://localhost:8080/health    # gateway responding
```

Or run the bundled verification script:

```bash
bash /usr/local/lib/hermes-deploy/scripts/configure.sh
```

---

## Configuration

Hermes settings live in `~/.hermes/config.yaml` on the deployed instance (written by `scripts/bootstrap.sh` from `config/hermes.yaml.tpl`):

```yaml
terminal:
  backend: docker          # sandboxed Docker execution
  container_cpu: 1
  container_memory: 5120   # 5 GB RAM
  container_disk: 51200    # 50 GB disk
  container_persistent: true

agent:
  max_turns: 90

compression:
  enabled: true
  threshold: 0.50

display:
  tool_progress: all
```

---

## Troubleshooting

**`gum: command not found`**

```bash
brew install gum   # macOS
# Linux: see https://github.com/charmbracelet/gum/releases
```

**`hermes doctor` fails after deploy**

The bootstrap script runs in the background on first boot. Give it ~3 min:

```bash
sudo tail -f /var/log/hermes-bootstrap.log
```

**API keys missing from `.hermes/.env`**

The instance queries the cloud vault via its IAM role. If the role was not yet propagated when bootstrap ran:

```bash
sudo systemctl restart hermes-gateway
# If still empty, verify IAM permissions:
# AWS:   aws iam simulate-principal-policy ...
# Azure: az role assignment list --assignee <principal-id>
# GCP:   gcloud projects get-iam-policy <project> | grep hermes
```

**Port 8080 not reachable**

Your IP changed. Re-run `hermes-deploy deploy` to update the firewall rule, or manually update the security group / NSG / firewall rule to your new IP.

**`terraform: command not found`**

```bash
brew install terraform   # macOS
# or: https://developer.hashicorp.com/terraform/install
```

---

## Project Structure

```
hermes-deploy/
├── hermes-deploy              Main executable
├── install.sh                 curl-pipe installer
├── lib/
│   ├── enums.sh               All enum definitions + validation helpers  ← extend here
│   ├── ui.sh                  gum wrappers, banner, post-deploy guide
│   ├── preflight.sh           Dependency + auth checks
│   ├── config.sh              Persist/read ~/.hermes-deploy/config
│   ├── aws.sh                 AWS wizard + management commands
│   ├── azure.sh               Azure wizard + management commands
│   └── gcp.sh                 GCP wizard + management commands
├── terraform/
│   ├── aws/                   EC2 + VPC + SSM + IAM (6 files)
│   ├── azure/                 VM + VNet + NSG + Key Vault (5 files)
│   └── gcp/                   Compute Engine + Firewall + Secret Manager (5 files)
├── scripts/
│   ├── bootstrap.sh           Cloud-init: install Hermes, pull secrets, register systemd
│   └── configure.sh           Post-deploy health-check (run on instance)
└── config/
    └── hermes.yaml.tpl        Hermes configuration template
```

---

## License

MIT
