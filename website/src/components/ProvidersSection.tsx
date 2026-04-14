"use client";
import { KeyRound } from "lucide-react";

const PROVIDERS = [
  {
    id: "openrouter",
    name: "OpenRouter",
    tagline: "600+ models via one API",
    color: "#f59e0b",
    envVar: "OPENROUTER_API_KEY",
    secretPath: "/hermes/openrouter_api_key",
    models: ["Llama 3.3 70B", "Mistral Large", "Gemma 3", "Claude 3.7", "…"],
    badge: "Recommended",
  },
  {
    id: "openai",
    name: "OpenAI",
    tagline: "GPT-5 · GPT-4.1 · o3",
    color: "#10b981",
    envVar: "OPENAI_API_KEY",
    secretPath: "/hermes/openai_api_key",
    models: ["gpt-5", "gpt-5.4", "gpt-4.1", "o3"],
    badge: null,
  },
  {
    id: "anthropic",
    name: "Anthropic",
    tagline: "Claude 4.6 Sonnet & Haiku",
    color: "#f97316",
    envVar: "ANTHROPIC_API_KEY",
    secretPath: "/hermes/anthropic_api_key",
    models: ["claude-4-6-sonnet", "claude-4-6-haiku", "claude-3-7-sonnet"],
    badge: null,
  },
  {
    id: "gemini",
    name: "Google Gemini",
    tagline: "Gemini 3.1 & 2.5 Pro",
    color: "#38bdf8",
    envVar: "GEMINI_API_KEY",
    secretPath: "/hermes/gemini_api_key",
    models: ["gemini-3.1-flash", "gemini-3.1-pro", "gemini-2.5-pro"],
    badge: null,
  },
];

export default function ProvidersSection() {
  return (
    <section id="providers" className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge badge-amber mb-4">LLM Providers</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Your model.{" "}
            <span className="gradient-text">Your choice.</span>
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Configure any combination of providers. Keys are injected directly into
            IAM-native secret vaults — never in config files or environment variables
            on disk.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {PROVIDERS.map(p => (
            <div
              key={p.id}
              className="card relative transition-all duration-300"
              style={{ borderColor: "var(--border)" }}
              onMouseEnter={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = p.color;
                el.style.boxShadow = `0 0 24px ${p.color}33`;
              }}
              onMouseLeave={e => {
                const el = e.currentTarget as HTMLElement;
                el.style.borderColor = "var(--border)";
                el.style.boxShadow = "none";
              }}
            >
              {p.badge && (
                <span
                  className="absolute top-3 right-3 text-xs px-2 py-0.5 rounded-full font-semibold"
                  style={{ background: `${p.color}22`, color: p.color, border: `1px solid ${p.color}55` }}
                >
                  {p.badge}
                </span>
              )}

              <div
                className="w-10 h-10 rounded-lg flex items-center justify-center mb-4"
                style={{ background: `${p.color}18`, border: `2px solid ${p.color}44` }}
              >
                <KeyRound size={18} style={{ color: p.color }} />
              </div>

              <h3 className="font-bold text-white text-sm mb-1">{p.name}</h3>
              <p className="text-xs mb-4" style={{ color: "var(--text-muted)" }}>{p.tagline}</p>

              {/* Models */}
              <div className="flex flex-wrap gap-1 mb-4">
                {p.models.slice(0, 3).map(m => (
                  <span
                    key={m}
                    className="text-xs px-1.5 py-0.5 rounded font-mono"
                    style={{ background: "var(--surface)", color: "var(--text-dim)", border: "1px solid var(--border)" }}
                  >
                    {m}
                  </span>
                ))}
                {p.models.length > 3 && (
                  <span className="text-xs" style={{ color: "var(--text-dim)" }}>+{p.models.length - 3}</span>
                )}
              </div>

              {/* Env var */}
              <code
                className="block text-xs font-mono px-2 py-1.5 rounded"
                style={{ background: "var(--terminal-bg)", color: p.color, border: "1px solid var(--border)" }}
              >
                {p.envVar}
              </code>
            </div>
          ))}
        </div>

        {/* Bottom note */}
        <p className="text-center text-sm mt-8" style={{ color: "var(--text-dim)" }}>
          At least one provider required · All others are optional · Mixed-provider setups fully supported
        </p>
      </div>
    </section>
  );
}
