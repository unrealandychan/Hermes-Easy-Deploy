const STEPS = [
  {
    n: "01",
    title: "Install the CLI",
    desc: "Run the one-line installer — it auto-detects macOS or Linux, installs gum, Terraform, and jq, then symlinks the binary to /usr/local/bin.",
    code: "curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash",
    accent: "#f59e0b",
  },
  {
    n: "02",
    title: "Run the wizard",
    desc: "Type hermes-agent-cloud and follow the interactive prompts. Choose your cloud, region, instance size, and configure your LLM API keys — all step-by-step.",
    code: "hermes-agent-cloud",
    accent: "#a78bfa",
  },
  {
    n: "03",
    title: "Deploy with Terraform",
    desc: "The CLI calls terraform apply in the background. Secrets are vaulted in SSM / Key Vault / Secret Manager automatically. A live spinner tracks every step.",
    code: "hermes-agent-cloud deploy --cloud aws",
    accent: "#38bdf8",
  },
  {
    n: "04",
    title: "Access your Agent",
    desc: "Get your public IP, SSH command, and gateway URL instantly. Use hermes-agent-cloud status, logs, or ssh at any time.",
    code: "hermes-agent-cloud status --cloud aws",
    accent: "#34d399",
  },
];

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge badge-amber mb-4">How It Works</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            From zero to{" "}
            <span className="gradient-text">live agent</span> in minutes.
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Four straightforward steps. No Terraform knowledge required.
          </p>
        </div>

        {/* Steps */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {STEPS.map(step => (
            <div key={step.n} className="card flex flex-col gap-4">
              {/* Number circle */}
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center text-lg font-black shrink-0"
                style={{
                  background: `${step.accent}18`,
                  border: `2px solid ${step.accent}55`,
                  color: step.accent,
                  fontFamily: "var(--font-geist-mono)",
                }}
              >
                {step.n}
              </div>

              <h3 className="font-bold text-base text-white">{step.title}</h3>
              <p className="text-sm leading-relaxed flex-1" style={{ color: "var(--text-muted)" }}>{step.desc}</p>

              <code
                className="block text-xs font-mono px-3 py-2 rounded-lg break-all"
                style={{
                  background: "var(--terminal-bg)",
                  color: step.accent,
                  border: "1px solid var(--border)",
                }}
              >
                {step.code}
              </code>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
