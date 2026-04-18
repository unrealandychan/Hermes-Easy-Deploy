"use client";
import { Lock, ShieldCheck, EyeOff, Network, Key } from "lucide-react";

const ITEMS = [
  {
    icon: Lock,
    title: "Secrets never leave your cloud",
    desc: "API keys are written to AWS SSM Parameter Store, Azure Key Vault, or GCP Secret Manager via Terraform — and fetched at boot over IAM-native metadata endpoints. No key ever passes through Hermes Agent Cloud's process.",
  },
  {
    icon: EyeOff,
    title: "Masked terminal input",
    desc: "All secret fields use gum input --password — the keystrokes are never echoed, never stored in shell history, and never written to a log file.",
  },
  {
    icon: Network,
    title: "IP-restricted firewall",
    desc: "SSH (22) and the gateway (8080) are locked to your public IP via the allowed_cidr Terraform variable. No ports are world-open by default.",
  },
  {
    icon: Key,
    title: "IAM least-privilege",
    desc: "EC2 instance roles, Azure Managed Identities, and GCP Service Accounts are each scoped to read only the secrets created for that deployment — nothing more.",
  },
  {
    icon: ShieldCheck,
    title: "Encrypted root disks",
    desc: "AWS uses gp3 encrypted EBS volumes. Azure uses Premium_LRS with encryption-at-rest. GCP uses pd-ssd with AES-256 Google-managed keys.",
  },
];

export default function SecuritySection() {
  return (
    <section id="security" className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge mb-4">Security Model</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Built secure{" "}
            <span className="gradient-text">from the ground up.</span>
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Security is not a checkbox — it is the default configuration in every
            cloud, every deploy, every time.
          </p>
        </div>

        {/* 5 cards in a staggered layout */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {ITEMS.map(({ icon: Icon, title, desc }, i) => (
            <div
              key={title}
              className={`card transition-all duration-200 ${i === 4 ? "sm:col-span-2 lg:col-span-1" : ""}`}
              style={{ borderColor: "var(--border)" }}
              onMouseEnter={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "#34d399aa";
                el.style.boxShadow = "0 0 24px #34d39933";
              }}
              onMouseLeave={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "var(--border)";
                el.style.boxShadow = "none";
              }}
            >
              <div
                className="w-10 h-10 rounded-lg flex items-center justify-center mb-4"
                style={{ background: "#34d39918", border: "1px solid #34d39944" }}
              >
                <Icon size={18} color="#34d399" />
              </div>
              <h3 className="font-bold text-white mb-2 text-sm">{title}</h3>
              <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>{desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
