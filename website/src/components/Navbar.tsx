import Link from "next/link";
import { Zap, Github } from "lucide-react";

export default function Navbar() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b"
      style={{ borderColor: "var(--border)", background: "rgba(8,9,14,0.85)", backdropFilter: "blur(12px)" }}>
      <div className="max-w-6xl mx-auto px-6 h-14 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 font-bold text-base">
          <span className="flex items-center justify-center w-7 h-7 rounded-md"
            style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}>
            <Zap size={15} color="#000" fill="#000" />
          </span>
          <span className="text-white">Hermes&#160;</span>
          <span style={{ color: "var(--amber)" }}>Agent</span>
          <span className="text-white">&#160;Cloud</span>
        </Link>

        {/* Nav links */}
        <nav className="hidden md:flex items-center gap-8 text-sm font-medium"
          style={{ color: "var(--text-muted)" }}>
          <a href="#features" className="hover:text-white transition-colors">Features</a>
          <a href="#clouds" className="hover:text-white transition-colors">Clouds</a>
          <a href="#providers" className="hover:text-white transition-colors">Providers</a>
          <a href="#security" className="hover:text-white transition-colors">Security</a>
          <a href="#install" className="hover:text-white transition-colors">Install</a>
        </nav>

        {/* CTA */}
        <a
          href="https://github.com/unrealandychan/Hermes-Agent-Cloud"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 px-4 py-1.5 rounded-md text-sm font-medium border transition-all hover:border-[#f59e0b]/50 hover:text-white"
          style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}
        >
          <Github size={15} />
          GitHub
        </a>
      </div>
    </header>
  );
}
