---
applyTo: "**/*.{ts,js,tsx,jsx,py,go,java,cs,rb,rs,swift,kt}"
---

# Clean Code + DDD Review Rules

Scope: readability and maintainability only. High-confidence findings only. Max 3 per file by impact.
No finding → reply: "No significant Clean Code issues found."

## Clean Code

| Rule | Severity | Flag when |
|---|---|---|
| `meaningful-names` | medium | Vague names: `data`, `tmp`, `res`, `doStuff`, `flag` |
| `single-responsibility` | high | Function/class mixes validation, persistence, business logic, side effects |
| `minimize-duplication` | high | Business logic repeated across 2+ functions or files |
| `avoid-deep-nesting` | medium | Nested `if/else` hides happy path; guard clauses would flatten it |
| `small-interfaces` | medium | 5+ mixed-purpose parameters |
| `named-constants` | low | Unnamed business literals in logic |
| `comment-why-not-what` | low | Comment restates code instead of explaining intent |
| `clear-error-handling` | medium | Silent failures, bare catch, generic exception, missing context |

## DDD (apply when domain modelling exists)

| Rule | Severity | Flag when |
|---|---|---|
| `ubiquitous-language` | medium | Generic name where a domain term exists |
| `bounded-context-violation` | high | Module imports another context's internals without ACL |
| `aggregate-integrity-bypass` | high | External code mutates aggregate bypassing the root |
| `value-object-mutability` | medium | Value-semantics object is mutable or identity-compared |
| `domain-logic-in-adapters` | high | Business rules in controllers, handlers, or DB adapters |
| `missing-acl` | medium | External model types referenced directly in domain code |
| `missing-repository-abstraction` | medium | Domain code calls ORM/SQL/HTTP directly |
| `missing-domain-event` | low | State transition side effects via direct calls |

## Output

```
## Clean Code Review
Files reviewed: N | Findings: N (High: N, Medium: N, Low: N)

### Finding N
- Severity: high | medium | low
- Rule: <rule-id>
- Location: <file>:<line>
- Problem: <what>
- Why it matters: <impact>
- Suggested fix: <action>
- Refactor example: (optional)
```

## Guardrails

- Skip formatting enforced by linters
- Every finding must cite a specific file and line
- No refactor demand when framework/business constraints apply
- No speculative findings — skip if unsure
- high/medium = mandatory · low = suggestion
