import { Zap, Github } from "lucide-react";

export default function Footer() {
  return (
    <footer className="border-t py-12 mt-0" style={{ borderColor: "var(--border)" }}>
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Brand */}
          <div className="flex items-center gap-2 font-bold">
            <span className="flex items-center justify-center w-6 h-6 rounded"
              style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}>
              <Zap size={13} color="#000" fill="#000" />
            </span>
            <span className="text-white">Hermes&#160;</span><span style={{ color: "var(--amber)" }}>Agent</span><span className="text-white">&#160;Cloud</span>
            <span className="text-xs ml-2 px-2 py-0.5 rounded-full border font-normal"
              style={{ borderColor: "var(--border)", color: "var(--text-dim)" }}>
              v1.0.1
            </span>
          </div>

          {/* Links */}
          <nav className="flex items-center gap-6 text-sm" style={{ color: "var(--text-muted)" }}>
            <a href="#features" className="hover:text-white transition-colors">Features</a>
            <a href="#install" className="hover:text-white transition-colors">Install</a>
            <a
              href="https://github.com/unrealandychan/Hermes-Agent-Cloud"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1.5 hover:text-white transition-colors"
            >
              <Github size={14} />
              GitHub
            </a>
          </nav>

          {/* Copyright */}
          <p className="text-sm" style={{ color: "var(--text-dim)" }}>
            MIT License · Open source · Free to use
          </p>
        </div>

        <div className="mt-8 pt-6 border-t text-center text-xs" style={{ borderColor: "var(--border)", color: "var(--text-dim)" }}>
          Built with{" "}
          <a href="https://nextjs.org" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Next.js 15</a>
          {" "}·{" "}
          <a href="https://github.com/charmbracelet/gum" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Charm gum</a>
          {" "}·{" "}
          <a href="https://developer.hashicorp.com/terraform" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Terraform</a>
          {" "}· Hermes Agent by NousResearch
        </div>
      </div>
    </footer>
  );
}
