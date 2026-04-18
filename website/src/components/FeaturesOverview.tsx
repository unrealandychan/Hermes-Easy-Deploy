"use client";
import { Sparkles, Cloud, ShieldCheck } from "lucide-react";

const PILLARS = [
  {
    icon: Sparkles,
    accent: "#f59e0b",
    title: "Beautiful Wizard TUI",
    desc:
      "Step-by-step interactive wizard powered by Charm gum. Real-time progress spinners, masked secret input, and colour-coded summaries — all in your terminal.",
    tags: ["gum", "interactive", "wizard-first"],
  },
  {
    icon: Cloud,
    accent: "#8b5cf6",
    title: "Multi-Cloud, One Tool",
    desc:
      "AWS EC2, Azure VM, and Google Compute Engine supported out of the box. Each cloud uses Terraform under the hood for reproducible, destroy-safe infrastructure.",
    tags: ["AWS", "Azure", "GCP", "Terraform"],
  },
  {
    icon: ShieldCheck,
    accent: "#34d399",
    title: "Zero-Plaintext Secrets",
    desc:
      "API keys are stored in AWS SSM Parameter Store, Azure Key Vault, or GCP Secret Manager via IAM-native access. No plaintext in config, scripts, or environment.",
    tags: ["IAM", "Vault", "SSM", "Key Vault"],
  },
];

export default function FeaturesOverview() {
  return (
    <section id="features" className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge badge-amber mb-4">Why Hermes Agent Cloud</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Everything you need.{" "}
            <span className="gradient-text">Nothing you don&apos;t.</span>
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            A self-contained Bash CLI that handles provisioning, secret wiring, and
            first-boot configuration — no GUI, no SaaS dependency.
          </p>
        </div>

        {/* Cards */}
        <div className="grid sm:grid-cols-3 gap-6">
          {PILLARS.map(({ icon: Icon, accent, title, desc, tags }) => (
            <div
              key={title}
              className="card relative overflow-hidden"
              style={{ borderColor: "var(--border)" }}
              onMouseEnter={e => { (e.currentTarget as HTMLElement).style.borderColor = accent; (e.currentTarget as HTMLElement).style.boxShadow = `0 0 24px ${accent}33`; }}
              onMouseLeave={e => { (e.currentTarget as HTMLElement).style.borderColor = "var(--border)"; (e.currentTarget as HTMLElement).style.boxShadow = "none"; }}
            >
              {/* icon */}
              <div
                className="w-11 h-11 rounded-lg flex items-center justify-center mb-5"
                style={{ background: `${accent}22`, border: `1px solid ${accent}55` }}
              >
                <Icon size={22} style={{ color: accent }} />
              </div>

              <h3 className="text-lg font-bold text-white mb-3">{title}</h3>
              <p className="text-sm leading-relaxed mb-5" style={{ color: "var(--text-muted)" }}>{desc}</p>

              {/* tags */}
              <div className="flex flex-wrap gap-1.5 mt-auto">
                {tags.map(t => (
                  <span
                    key={t}
                    className="text-xs px-2 py-0.5 rounded-full font-mono"
                    style={{ background: `${accent}18`, color: accent, border: `1px solid ${accent}44` }}
                  >
                    {t}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
