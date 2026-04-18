"use client";
import { useState, useEffect } from "react";

const LINES = [
  { delay: 0,    text: "$ hermes-agent-cloud",                  type: "cmd"   },
  { delay: 600,  text: "",                                  type: "blank" },
  { delay: 700,  text: "  ⚡  Hermes Agent Cloud  v1.0.1", type: "banner"},
  { delay: 900,  text: "  Deploy the Hermes Agent anywhere.", type: "dim" },
  { delay: 1100, text: "",                                  type: "blank" },
  { delay: 1300, text: "  [1/6] Cloud provider   →  AWS",  type: "step"  },
  { delay: 1700, text: "  [2/6] AWS Region       →  ap-east-1 (Hong Kong)", type: "step" },
  { delay: 2100, text: "  [3/6] Instance type    →  t3.large (2 vCPU / 8 GB)", type: "step" },
  { delay: 2500, text: "  [4/6] SSH key          →  ~/.ssh/id_ed25519.pub", type: "step" },
  { delay: 2900, text: "  [5/6] API keys         →  ✓  2 providers configured", type: "step" },
  { delay: 3400, text: "  [6/6] Confirm deploy   →  Yes",  type: "step"  },
  { delay: 3800, text: "",                                  type: "blank" },
  { delay: 3900, text: "  ⠸  Applying Terraform…",         type: "spin"  },
  { delay: 5000, text: "  ✓  Hermes Agent deployed!",      type: "ok"    },
  { delay: 5200, text: "  ✓  Public IP:  43.198.77.12",    type: "ok"    },
  { delay: 5400, text: "  ✓  Gateway:    http://43.198.77.12:8080", type: "ok" },
  { delay: 5600, text: "",                                  type: "blank" },
  { delay: 5700, text: "  SSH:    ssh ubuntu@43.198.77.12", type: "hint" },
  { delay: 5900, text: "  Logs:   hermes-agent-cloud logs --cloud aws", type: "hint" },
  { delay: 6100, text: "  Destroy: hermes-agent-cloud destroy --cloud aws", type: "hint" },
];

function colorFor(type: string) {
  switch (type) {
    case "cmd":    return "#ffffff";
    case "banner": return "#f59e0b";
    case "dim":    return "#6b7280";
    case "step":   return "#d1d5db";
    case "spin":   return "#a78bfa";
    case "ok":     return "#34d399";
    case "hint":   return "#7dd3fc";
    default:       return "#9ca3af";
  }
}

export default function TerminalDemo() {
  const [visibleCount, setVisibleCount] = useState(0);
  const [restarting, setRestarting] = useState(false);

  useEffect(() => {
    if (restarting) return;
    const timers = LINES.map((line, i) =>
      setTimeout(() => setVisibleCount(i + 1), line.delay)
    );
    const restart = setTimeout(() => {
      setRestarting(true);
      setTimeout(() => {
        setVisibleCount(0);
        setRestarting(false);
      }, 1200);
    }, 8500);
    return () => { timers.forEach(clearTimeout); clearTimeout(restart); };
  }, [restarting]);

  return (
    <div className="terminal rounded-xl w-full max-w-xl mx-auto text-sm font-mono leading-relaxed shadow-2xl">
      {/* dots */}
      <div className="terminal-bar">
        <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#ff5f57" }} />
        <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#f59e0b" }} />
        <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#28c840" }} />
        <span className="ml-auto text-xs" style={{ color: "var(--text-dim)" }}>Hermes Agent Cloud — bash</span>
      </div>

      <div className="terminal-body min-h-[320px]">
        {LINES.slice(0, visibleCount).map((line, i) => (
          <div key={i} style={{ color: colorFor(line.type), minHeight: "1.4rem" }}>
            {line.text || <br />}
          </div>
        ))}
        {visibleCount < LINES.length && (
          <span
            className="inline-block w-2 h-[1.1em] align-middle"
            style={{
              background: "#f59e0b",
              animation: "cursor-blink 1s step-end infinite",
              verticalAlign: "text-bottom",
            }}
          />
        )}
      </div>
    </div>
  );
}
