"use client";
import { Github, BookOpen, Mic, Code2, ExternalLink } from "lucide-react";

const SKILLS = [
  "AI Agents", "Multi-agent Systems", "LLM Orchestration",
  "Distributed Systems", "Go", "Python", "TypeScript",
  "Terraform", "AWS", "Kubernetes", "MLOps",
];

const HIGHLIGHTS = [
  {
    icon: Code2,
    label: "AI Engineer",
    desc: "Building production AI agent systems and multi-agent orchestration frameworks.",
  },
  {
    icon: Mic,
    label: "Podcast Host · Debug 人生",
    desc: "Running a Cantonese tech podcast — breaking down AI, engineering, and industry news for HK developers.",
  },
  {
    icon: BookOpen,
    label: "Technical Writer",
    desc: "Writing deep-dive articles on distributed systems, AI architecture, and engineering craft on Medium.",
  },
];

export default function AboutSection() {
  return (
    <section id="about" className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Section heading */}
        <div className="text-center mb-16">
          <p className="text-xs font-semibold tracking-widest uppercase mb-3"
            style={{ color: "var(--amber)" }}>
            THE BUILDER
          </p>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            About the Author
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            Hermes Agent Cloud is built and maintained by{" "}
            <strong className="text-white">Eddie Chan</strong>, an AI engineer based in Hong Kong.
          </p>
        </div>

        {/* Main card */}
        <div className="grid lg:grid-cols-5 gap-8 items-start">

          {/* Left — identity card */}
          <div className="lg:col-span-2">
            <div
              className="rounded-2xl p-8 border h-full relative overflow-hidden"
              style={{ background: "var(--surface)", borderColor: "var(--border)" }}
            >
              {/* Glow */}
              <div
                className="absolute -top-10 -right-10 w-40 h-40 rounded-full blur-3xl pointer-events-none opacity-25"
                style={{ background: "radial-gradient(circle,#f59e0b,transparent 70%)" }}
              />

              {/* Avatar placeholder — initials */}
              <div
                className="w-20 h-20 rounded-2xl flex items-center justify-center font-bold text-2xl mb-6 relative z-10"
                style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)", color: "#000" }}
              >
                EC
              </div>

              <h3 className="text-xl font-bold text-white mb-1 relative z-10">Eddie Chan</h3>
              <p className="text-sm mb-5 relative z-10" style={{ color: "var(--amber)" }}>
                AI Engineer · Hong Kong
              </p>

              <p className="text-sm leading-relaxed mb-6 relative z-10" style={{ color: "var(--text-muted)" }}>
                Passionate about building agents that actually work in production.
                I created Hermes Agent Cloud because deploying AI infrastructure
                should be a first-class experience — not a Terraform archaeology project.
              </p>

              {/* Skill tags */}
              <div className="flex flex-wrap gap-2 mb-6 relative z-10">
                {SKILLS.map(s => (
                  <span
                    key={s}
                    className="text-xs px-2.5 py-1 rounded-full border font-medium"
                    style={{ borderColor: "var(--border)", color: "var(--text-muted)", background: "var(--bg)" }}
                  >
                    {s}
                  </span>
                ))}
              </div>

              {/* Links */}
              <div className="flex flex-col gap-3 relative z-10">
                <a
                  href="https://github.com/unrealandychan"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-sm font-medium transition-colors hover:text-white"
                  style={{ color: "var(--text-muted)" }}
                >
                  <Github size={16} />
                  github.com/unrealandychan
                  <ExternalLink size={12} className="opacity-50" />
                </a>
                <a
                  href="https://medium.com/@unrealandychan"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-sm font-medium transition-colors hover:text-white"
                  style={{ color: "var(--text-muted)" }}
                >
                  <BookOpen size={16} />
                  medium.com/@unrealandychan
                  <ExternalLink size={12} className="opacity-50" />
                </a>
              </div>
            </div>
          </div>

          {/* Right — highlights */}
          <div className="lg:col-span-3 flex flex-col gap-5">
            {HIGHLIGHTS.map(({ icon: Icon, label, desc }) => (
              <div
                key={label}
                className="rounded-xl p-6 border flex items-start gap-5 transition-all duration-200 group"
                style={{ background: "var(--surface)", borderColor: "var(--border)" }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.borderColor = "#f59e0b55"; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.borderColor = "var(--border)"; }}
              >
                <div
                  className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                  style={{ background: "rgba(245,158,11,0.12)", color: "var(--amber)" }}
                >
                  <Icon size={20} />
                </div>
                <div>
                  <p className="font-semibold text-white mb-1">{label}</p>
                  <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>{desc}</p>
                </div>
              </div>
            ))}

            {/* Quote / mission */}
            <div
              className="rounded-xl p-6 border-l-2 mt-2"
              style={{
                background: "rgba(245,158,11,0.05)",
                borderColor: "var(--amber)",
              }}
            >
              <p className="text-sm italic leading-relaxed" style={{ color: "var(--text-muted)" }}>
                &ldquo;Good tooling should feel like magic the first time — and stay out of your way
                every time after that. That&rsquo;s the bar I hold Hermes Agent Cloud to.&rdquo;
              </p>
              <p className="text-xs mt-3 font-semibold" style={{ color: "var(--amber)" }}>
                — Eddie Chan
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
