# Hermes Agent Cloud

> One command. Three clouds. Four LLM providers.
> Deploy the [Hermes Agent](https://github.com/NousResearch/hermes) to AWS, Azure, or GCP with a beautiful wizard-first CLI — zero plaintext secrets, zero manual infra wiring.

[![License: MIT](https://img.shields.io/badge/license-MIT-amber.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-unrealandychan%2FHermes--Agent--Cloud-181717?logo=github)](https://github.com/unrealandychan/Hermes-Agent-Cloud)

---

## Monorepo Structure

```
Hermes-Agent-Cloud/
│
├── cli/                                 # 🖥️  The CLI tool
│   ├── hermes-deploy                    # Main executable (bash, chmod +x)
│   ├── install.sh                       # One-line installer (detects macOS / Linux)
│   │
│   ├── lib/                        # Shared bash libraries
│   │   ├── enums.sh                # ⭐ All valid values + validation functions (extend here)
│   │   ├── ui.sh                   # gum wrappers — wizard, banners, spinners, post-deploy guide
│   │   ├── preflight.sh            # Dependency checks (gum, terraform, jq, cloud CLIs)
│   │   ├── config.sh               # ~/.hermes-agent-cloud/config key-value store
│   │   ├── aws.sh                  # AWS wizard + status/ssh/logs/secrets/destroy
│   │   ├── azure.sh                # Azure wizard + status/ssh/logs/secrets/destroy
│   │   └── gcp.sh                  # GCP wizard + status/ssh/logs/secrets/destroy
│   │
│   ├── terraform/
│   │   ├── aws/                    # EC2 + Security Group + IAM + SSM Parameter Store
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── security_group.tf
│   │   │   ├── iam.tf
│   │   │   └── ssm.tf
│   │   ├── azure/                  # VM + VNet + NSG + Azure Key Vault + Managed Identity
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── network.tf
│   │   │   └── keyvault.tf
│   │   └── gcp/                    # Compute Engine + Firewall + Secret Manager + Service Account
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── firewall.tf
│   │       └── secretmanager.tf
│   │
│   ├── scripts/
│   │   ├── bootstrap.sh            # VM user-data: installs Docker, Hermes, pulls secrets, sets up systemd
│   │   └── configure.sh            # 7-point on-instance health check
│   │
│   ├── config/
│   │   └── hermes.yaml.tpl         # Hermes Agent config template (rendered at deploy time)
│   │
│   ├── README.md                   # CLI-specific documentation
│   └── RELEASE-NOTE.md             # Changelog
│
├── website/                             # 🌐  Marketing website (Next.js 15)
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx          # Root layout — Geist fonts, metadata
│   │   │   ├── page.tsx            # Page assembly — imports all sections
│   │   │   ├── globals.css         # Design tokens, utility classes
│   │   │   └── error.tsx           # Next.js error boundary
│   │   └── components/
│   │       ├── Navbar.tsx          # Fixed top nav with anchor links
│   │       ├── Hero.tsx            # Full-width hero + animated TerminalDemo
│   │       ├── TerminalDemo.tsx    # Auto-replaying wizard terminal animation
│   │       ├── FeaturesOverview.tsx# 3 pillar cards
│   │       ├── CloudsSection.tsx   # AWS / Azure / GCP detail cards
│   │       ├── ProvidersSection.tsx# 4 LLM provider cards
│   │       ├── FeatureGrid.tsx     # 12-feature grid
│   │       ├── HowItWorks.tsx      # 4-step numbered guide
│   │       ├── SecuritySection.tsx # Security guarantee cards
│   │       ├── InstallSection.tsx  # curl one-liner + commands table
│   │       └── Footer.tsx          # Brand, nav, license
│   ├── next.config.ts
│   ├── postcss.config.mjs
│   ├── tsconfig.json
│   └── package.json
│
├── .gitignore                      # Monorepo-wide ignores
└── README.md                       # This file
```

---

## Packages at a Glance

| Package | Language | Purpose |
|---|---|---|
| `cli/` | Bash + Terraform | CLI that provisions Hermes Agent on cloud VMs |
| `website/` | Next.js 15 / TypeScript | Marketing website |

---

## Quick Start

### Install the CLI

```bash
curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/unrealandychan/Hermes-Agent-Cloud
cd Hermes-Agent-Cloud/cli
./install.sh
```

### Run

```bash
hermes-agent-cloud                          # interactive wizard
hermes-agent-cloud deploy --cloud aws       # flags mode
hermes-agent-cloud status --cloud azure
hermes-agent-cloud ssh    --cloud gcp
hermes-agent-cloud logs   --cloud aws
hermes-agent-cloud secrets --cloud azure
hermes-agent-cloud destroy --cloud aws
```

---

## Run the Website Locally

```bash
cd website
npm install
npm run dev          # http://localhost:3000
```

---

## Cloud Support

| Cloud | Compute | Secret Store | SSH Options |
|---|---|---|---|
| AWS | EC2 (Ubuntu 24.04) | SSM Parameter Store | Direct SSH · SSM Session Manager |
| Azure | VM Standard_D2s_v3 | Azure Key Vault | Direct SSH · az ssh extension |
| GCP | Compute Engine e2-standard-2 | Secret Manager | Direct SSH · gcloud compute ssh |

## LLM Providers

| Provider | Env Var | Notes |
|---|---|---|
| OpenRouter | `OPENROUTER_API_KEY` | 600+ models, recommended |
| OpenAI | `OPENAI_API_KEY` | GPT-5, GPT-5.4, GPT-4.1, o3 |
| Anthropic | `ANTHROPIC_API_KEY` | Claude 4.6 Sonnet, Claude 4.6 Haiku |
| Google Gemini | `GEMINI_API_KEY` | Gemini 3.1 Flash / Pro, Gemini 2.5 Pro |

At least one provider required. Mixed-provider setups fully supported.

---

## Extending

All valid option values live in a single file — **`cli/lib/enums.sh`**.
To add a new cloud region, instance type, or LLM provider, edit only that file.

---

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes
4. Open a Pull Request against `main`

---

## License

MIT © [unrealandychan](https://github.com/unrealandychan)
