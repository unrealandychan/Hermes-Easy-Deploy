"use client";
import { useState } from "react";
import { Copy, Check } from "lucide-react";

const INSTALL_CMD = `curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash`;

const COMMANDS = [
  { cmd: "hermes-agent-cloud",                          desc: "Launch interactive wizard" },
  { cmd: "hermes-agent-cloud deploy --cloud aws",       desc: "Deploy to AWS (flags mode)" },
  { cmd: "hermes-agent-cloud status --cloud azure",     desc: "Show running instance info" },
  { cmd: "hermes-agent-cloud ssh --cloud gcp",          desc: "SSH into the instance" },
  { cmd: "hermes-agent-cloud logs --cloud aws",         desc: "Tail journalctl logs" },
  { cmd: "hermes-agent-cloud secrets --cloud azure",    desc: "Update API keys in Key Vault" },
  { cmd: "hermes-agent-cloud destroy --cloud aws",      desc: "Tear down infra completely" },
];

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  async function copy() {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  }
  return (
    <button
      onClick={copy}
      className="p-1.5 rounded transition-all duration-150"
      style={{ background: copied ? "#34d39922" : "#ffffff11", color: copied ? "#34d399" : "#9ca3af" }}
      aria-label="Copy"
    >
      {copied ? <Check size={13} /> : <Copy size={13} />}
    </button>
  );
}

export default function InstallSection() {
  return (
    <section id="install" className="py-24 px-6" style={{ background: "var(--surface)" }}>
      <div className="max-w-4xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-12">
          <span className="badge badge-amber mb-4">Install</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            One line.{" "}
            <span className="gradient-text">Any machine.</span>
          </h2>
          <p className="text-base max-w-lg mx-auto" style={{ color: "var(--text-muted)" }}>
            Installs gum, Terraform, jq, and Hermes Agent Cloud. Works on macOS and
            Debian/Ubuntu Linux.
          </p>
        </div>

        {/* Install command box */}
        <div className="terminal rounded-xl mb-8 shadow-2xl">
          <div className="terminal-bar">
            <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#ff5f57" }} />
            <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#f59e0b" }} />
            <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#28c840" }} />
            <span className="ml-auto text-xs" style={{ color: "var(--text-dim)" }}>your terminal</span>
          </div>
          <div className="terminal-body flex items-center justify-between gap-4">
            <code
              className="font-mono text-sm flex-1"
              style={{ color: "#f59e0b" }}
            >
              {INSTALL_CMD}
            </code>
            <CopyButton text={INSTALL_CMD} />
          </div>
        </div>

        {/* Or via git */}
        <p className="text-center text-sm mb-10" style={{ color: "var(--text-dim)" }}>
          Or clone manually:{" "}
          <code className="font-mono" style={{ color: "var(--text-muted)" }}>
            git clone https://github.com/unrealandychan/Hermes-Agent-Cloud &amp;&amp; cd Hermes-Agent-Cloud &amp;&amp; ./install.sh
          </code>
        </p>

        {/* Commands table */}
        <div className="rounded-xl border overflow-hidden" style={{ borderColor: "var(--border)" }}>
          <div className="px-5 py-3 border-b" style={{ borderColor: "var(--border)", background: "#f59e0b0a" }}>
            <p className="text-sm font-semibold text-white">Available Commands</p>
          </div>
          <div className="divide-y" style={{ borderColor: "var(--border)" }}>
            {COMMANDS.map(({ cmd, desc }) => (
              <div
                key={cmd}
                className="flex items-center justify-between gap-4 px-5 py-3 transition-colors"
                style={{ background: "var(--card-bg)" }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.background = "#f59e0b08"; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.background = "var(--card-bg)"; }}
              >
                <code className="font-mono text-xs flex-1" style={{ color: "#f59e0b" }}>
                  {cmd}
                </code>
                <span className="text-xs" style={{ color: "var(--text-dim)" }}>{desc}</span>
                <CopyButton text={cmd} />
              </div>
            ))}
          </div>
        </div>

        {/* Prerequisites */}
        <div
          className="mt-8 p-5 rounded-xl border text-sm"
          style={{ borderColor: "var(--border)", background: "var(--card-bg)" }}
        >
          <p className="font-semibold text-white mb-2">Prerequisites</p>
          <ul className="space-y-1" style={{ color: "var(--text-muted)" }}>
            {[
              "Cloud CLI (aws / az / gcloud) with valid credentials",
              "Terraform ≥ 1.6 (installer will set this up)",
              "gum ≥ 0.14 (installer will set this up)",
              "At least one LLM API key (OpenRouter, OpenAI, Anthropic, or Gemini)",
            ].map(item => (
              <li key={item} className="flex items-start gap-2">
                <span style={{ color: "#f59e0b" }}>→</span>
                {item}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
