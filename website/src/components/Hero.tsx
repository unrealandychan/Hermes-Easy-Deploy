"use client";
import { Github, Download } from "lucide-react";
import TerminalDemo from "./TerminalDemo";

export default function Hero() {
  return (
    <section className="mesh-bg relative pt-36 pb-24 px-6 overflow-hidden">
      {/* Amber glow top-left */}
      <div
        className="absolute top-24 left-1/4 w-96 h-96 rounded-full pointer-events-none blur-3xl opacity-20"
        style={{ background: "radial-gradient(circle,#f59e0b,transparent 70%)" }}
      />
      {/* Purple glow top-right */}
      <div
        className="absolute top-40 right-1/4 w-80 h-80 rounded-full pointer-events-none blur-3xl opacity-15"
        style={{ background: "radial-gradient(circle,#8b5cf6,transparent 70%)" }}
      />

      <div className="max-w-6xl mx-auto relative z-10">
        <div className="flex flex-col lg:flex-row items-center gap-16">
          {/* Left: copy */}
          <div className="flex-1 text-center lg:text-left">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 badge badge-amber mb-6">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-400 inline-block animate-pulse" />
              v1.0.1 · Now Available · Open Source
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold leading-tight mb-6 tracking-tight">
              Deploy{" "}
              <span className="gradient-text">Hermes Agent</span>
              <br />
              to Any Cloud —
              <br />
              In One Command.
            </h1>

            <p
              className="text-lg sm:text-xl mb-10 max-w-xl mx-auto lg:mx-0 leading-relaxed"
              style={{ color: "var(--text-muted)" }}
            >
              A beautiful, wizard-first CLI that provisions your{" "}
              <strong className="text-white">Hermes Agent</strong> on AWS, Azure, or GCP
              with secrets vaulted in IAM-native stores — zero plaintext, zero hassle.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <a
                href="#install"
                className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg font-semibold text-sm transition-all duration-200 text-black"
                style={{
                  background: "var(--amber)",
                  boxShadow: "0 0 24px #f59e0b55",
                }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.boxShadow = "0 0 36px #f59e0baa"; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.boxShadow = "0 0 24px #f59e0b55"; }}
              >
                <Download size={16} />
                Install Free
              </a>
              <a
                href="https://github.com/unrealandychan/Hermes-Agent-Cloud"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg font-semibold text-sm border transition-all duration-200 text-white"
                style={{ borderColor: "var(--border)" }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.borderColor = "#f59e0b"; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.borderColor = "var(--border)"; }}
              >
                <Github size={16} />
                View on GitHub
              </a>
            </div>

            {/* Cloud badges */}
            <div className="flex items-center gap-3 mt-8 justify-center lg:justify-start flex-wrap">
              {["AWS", "Azure", "GCP"].map(cloud => (
                <span key={cloud} className="badge">{cloud}</span>
              ))}
              <span className="text-xs ml-1" style={{ color: "var(--text-dim)" }}>
                Terraform-powered · IAM-native secrets
              </span>
            </div>
          </div>

          {/* Right: terminal */}
          <div className="flex-1 w-full max-w-xl">
            <TerminalDemo />
          </div>
        </div>
      </div>
    </section>
  );
}
