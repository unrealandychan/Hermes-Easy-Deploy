"use client";
import {
  Terminal,
  ShieldCheck,
  Container,
  Activity,
  Stethoscope,
  MapPin,
  Layers,
  Eye,
  RefreshCw,
  Zap,
  FileCode2,
  HardDrive,
} from "lucide-react";

const FEATURES = [
  { icon: Terminal,    label: "Interactive Wizard",        desc: "Step-by-step gum wizard for every cloud" },
  { icon: ShieldCheck, label: "Enum Validation",           desc: "All options validated against typed enums" },
  { icon: Container,   label: "Docker Sandbox",            desc: "5 GB RAM · 50 GB disk · container isolation" },
  { icon: Activity,    label: "Systemd Auto-start",        desc: "hermes-gateway boots on every instance reboot" },
  { icon: Stethoscope, label: "hermes doctor",             desc: "7-point health check runs after every deploy" },
  { icon: MapPin,      label: "Post-deploy Access Guide",  desc: "SSH, gateway, logs, and destroy — all in one output" },
  { icon: Layers,      label: "Extensible Providers",      desc: "Add new LLM providers in a single enums.sh edit" },
  { icon: Eye,         label: "Masked Secret Input",       desc: "API keys never echo to screen or shell history" },
  { icon: RefreshCw,   label: "Idempotent Destroy",        desc: "hermes-agent-cloud destroy tears down cloud + config" },
  { icon: Zap,         label: "1-line Install",            desc: "curl | bash · auto-detects macOS or Linux" },
  { icon: FileCode2,   label: "Config Persistence",        desc: "~/.hermes-agent-cloud/config, key/value store" },
  { icon: HardDrive,   label: "gp3 / SSD Disks",          desc: "Encrypted root disks on all three clouds" },
];

export default function FeatureGrid() {
  return (
    <section className="py-24 px-6" style={{ background: "var(--surface)" }}>
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge mb-4">Feature Grid</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Zero compromises.
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Every detail of the deploy experience is handled so you can focus on
            building with Hermes Agent — not debugging infra.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {FEATURES.map(({ icon: Icon, label, desc }) => (
            <div
              key={label}
              className="flex items-start gap-4 p-5 rounded-xl border transition-all duration-200"
              style={{ borderColor: "var(--border)", background: "var(--card-bg)" }}
              onMouseEnter={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "#f59e0b55";
                el.style.background = "#f59e0b08";
              }}
              onMouseLeave={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "var(--border)";
                el.style.background = "var(--card-bg)";
              }}
            >
              <span
                className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0 mt-0.5"
                style={{ background: "#f59e0b1a", border: "1px solid #f59e0b44" }}
              >
                <Icon size={17} color="#f59e0b" />
              </span>
              <div>
                <p className="font-semibold text-sm text-white mb-1">{label}</p>
                <p className="text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
