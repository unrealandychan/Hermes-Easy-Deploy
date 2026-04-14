"use client";
import { Server, Lock, Cpu, Network } from "lucide-react";

const CLOUDS = [
  {
    id: "aws",
    name: "Amazon Web Services",
    short: "AWS",
    color: "#f59e0b",
    bgGlyph: "aws",
    services: [
      { icon: Server, label: "EC2", detail: "Ubuntu 24.04 · t3.large default" },
      { icon: Lock, label: "SSM Parameter Store", detail: "SecureString · /hermes/* prefix" },
      { icon: Cpu, label: "IAM Instance Profile", detail: "SSMManagedInstanceCore + inline" },
      { icon: Network, label: "Security Group", detail: "SSH 22 + Gateway 8080 by CIDR" },
    ],
    ssh: "Direct SSH or AWS Session Manager (no open port needed)",
    regions: "18 regions pre-validated",
    tfNote: "Fetches latest Ubuntu 24.04 AMI automatically",
  },
  {
    id: "azure",
    name: "Microsoft Azure",
    short: "Azure",
    color: "#38bdf8",
    bgGlyph: "az",
    services: [
      { icon: Server, label: "Virtual Machine", detail: "Standard_D2s_v3 · Ubuntu 24.04" },
      { icon: Lock, label: "Azure Key Vault", detail: "HSM-backed · Managed Identity access" },
      { icon: Cpu, label: "Managed Identity", detail: "SystemAssigned · auto key-vault access" },
      { icon: Network, label: "NSG + VNet", detail: "Dedicated subnet · 2 inbound rules" },
    ],
    ssh: "Direct SSH or az ssh extension (no public key stored in Azure)",
    regions: "12 locations pre-validated",
    tfNote: "Resource group created and tagged per deploy",
  },
  {
    id: "gcp",
    name: "Google Cloud Platform",
    short: "GCP",
    color: "#34d399",
    bgGlyph: "gcp",
    services: [
      { icon: Server, label: "Compute Engine", detail: "e2-standard-2 · Ubuntu 24.04 LTS" },
      { icon: Lock, label: "Secret Manager", detail: "CMEK optional · per-secret IAM binding" },
      { icon: Cpu, label: "Service Account", detail: "secretAccessor role per secret" },
      { icon: Network, label: "Firewall rules", detail: "Tag-scoped · SSH + 8080" },
    ],
    ssh: "gcloud compute ssh or direct after firewall open",
    regions: "10 regions pre-validated",
    tfNote: "Enables Secret Manager & Compute APIs automatically",
  },
];

export default function CloudsSection() {
  return (
    <section id="clouds" className="py-24 px-6" style={{ background: "var(--surface)" }}>
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-14">
          <span className="badge mb-4">Multi-Cloud</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            One wizard.{" "}
            <span className="gradient-text">Three clouds.</span>
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Every cloud provider ships its own Terraform module, IAM wiring, and
            secret injection strategy — all consistent from the CLI&apos;s perspective.
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          {CLOUDS.map(cloud => (
            <div
              key={cloud.id}
              className="card transition-all duration-300"
              style={{ borderColor: "var(--border)" }}
              onMouseEnter={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = cloud.color;
                el.style.boxShadow = `0 0 28px ${cloud.color}33`;
              }}
              onMouseLeave={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "var(--border)";
                el.style.boxShadow = "none";
              }}
            >
              {/* Cloud header */}
              <div className="flex items-center gap-3 mb-6">
                <span
                  className="w-10 h-10 rounded-lg flex items-center justify-center text-xs font-black font-mono"
                  style={{ background: `${cloud.color}22`, color: cloud.color, border: `2px solid ${cloud.color}55` }}
                >
                  {cloud.bgGlyph.toUpperCase()}
                </span>
                <div>
                  <p className="font-bold text-white text-sm">{cloud.name}</p>
                  <p className="text-xs" style={{ color: cloud.color }}>{cloud.regions}</p>
                </div>
              </div>

              {/* Services */}
              <ul className="space-y-3 mb-6">
                {cloud.services.map(({ icon: Icon, label, detail }) => (
                  <li key={label} className="flex items-start gap-2.5">
                    <Icon size={14} className="mt-0.5 shrink-0" style={{ color: cloud.color }} />
                    <div>
                      <span className="text-sm font-semibold text-white">{label}</span>
                      <span className="text-xs block mt-0.5" style={{ color: "var(--text-dim)" }}>{detail}</span>
                    </div>
                  </li>
                ))}
              </ul>

              <div
                className="text-xs rounded-lg p-3 font-mono"
                style={{ background: "var(--terminal-bg)", color: "var(--text-muted)", border: "1px solid var(--border)" }}
              >
                <span style={{ color: cloud.color }}>SSH: </span>{cloud.ssh}
              </div>
              <p className="text-xs mt-3 italic" style={{ color: "var(--text-dim)" }}>{cloud.tfNote}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
