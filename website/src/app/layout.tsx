import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./globals.css";

export const metadata: Metadata = {
  title: "Hermes Agent Cloud — Deploy Hermes Agent to Any Cloud",
  description:
    "Beautiful wizard-first CLI to deploy the Hermes Agent to AWS, Azure, or GCP in one command. Supports OpenAI, Anthropic, Gemini, and OpenRouter. Zero secrets in infrastructure code.",
  keywords: ["hermes agent", "deploy", "AWS", "Azure", "GCP", "CLI", "LLM", "OpenAI", "Anthropic"],
  openGraph: {
    title: "Hermes Agent Cloud — Deploy Hermes Agent to Any Cloud",
    description:
      "One command. Three clouds. Four LLM providers. Beautiful TUI powered by Charm gum.",
    type: "website",
    url: "https://github.com/unrealandychan/Hermes-Agent-Cloud",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="antialiased">{children}</body>
    </html>
  );
}
