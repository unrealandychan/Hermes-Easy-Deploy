#!/usr/bin/env bash
# lint-and-report.sh — Run linters and prepare output for LLM analysis.
#                      Supports single-language projects AND monorepos.
#
# Usage:
#   ./scripts/lint-and-report.sh [OPTIONS] [PATH]
#
# Options:
#   --lang LANG    python | typescript | go | java | csharp | auto (default: auto)
#   --monorepo     Scan sub-packages; detect each package's language independently
#   --depth N      How many directory levels deep to scan for packages (default: 2)
#   --out FILE     Output file for combined lint results (default: lint-output.txt)
#   --help         Show this help
#
# Positional:
#   PATH           Root directory to lint (default: current directory)
#
# Examples:
#   # Single project, auto-detect language
#   ./scripts/lint-and-report.sh
#
#   # Explicit language and path
#   ./scripts/lint-and-report.sh --lang python src/
#
#   # Monorepo: scan all packages up to 2 levels deep
#   ./scripts/lint-and-report.sh --monorepo
#
#   # Monorepo with deeper nesting
#   ./scripts/lint-and-report.sh --monorepo --depth 3 packages/

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
LANG="auto"
MONOREPO=false
DEPTH=2
ROOT_TARGET="."
DATE_SLUG="$(date '+%Y-%m-%d')"
REPORT_DIR="reports/${DATE_SLUG}"
OUTPUT_FILE=""     # resolved after arg parsing
CUSTOM_OUT=false   # true when --out was passed explicitly

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)       LANG="$2";                    shift 2 ;;
    --monorepo)   MONOREPO=true;                shift ;;
    --depth)      DEPTH="$2";                   shift 2 ;;
    --report-dir) REPORT_DIR="$2";              shift 2 ;;
    --out)        OUTPUT_FILE="$2"; CUSTOM_OUT=true; shift 2 ;;
    --help)
      sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      ROOT_TARGET="$1"
      shift
      ;;
  esac
done

ROOT_TARGET="$(cd "$ROOT_TARGET" && pwd)"

# ── Resolve output paths ──────────────────────────────────────────────────────
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/report.md"
[[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="${REPORT_DIR}/lint-output.txt"

# ── Language detection for a given directory ──────────────────────────────────
detect_lang() {
  local dir="$1"
  # Check manifest files first (fast, reliable)
  [[ -f "$dir/pyproject.toml" || -f "$dir/setup.py" || -f "$dir/requirements.txt" ]] && { echo "python";     return; }
  [[ -f "$dir/go.mod" ]]                                                               && { echo "go";         return; }
  [[ -f "$dir/pom.xml" || -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]     && { echo "java";       return; }
  find "$dir" -maxdepth 1 -name "*.csproj" -print -quit 2>/dev/null | grep -q .        && { echo "csharp";     return; }
  # package.json present AND at least one .ts/.tsx file → TypeScript; otherwise JavaScript
  if [[ -f "$dir/package.json" ]]; then
    find "$dir" -maxdepth 3 \( -name "*.ts" -o -name "*.tsx" \) -print -quit 2>/dev/null | grep -q . \
      && { echo "typescript"; return; } \
      || { echo "javascript"; return; }
  fi
  # Fallback: look for source files
  find "$dir" -maxdepth 2 -name "*.py"   -print -quit 2>/dev/null | grep -q . && { echo "python";     return; }
  find "$dir" -maxdepth 2 -name "*.go"   -print -quit 2>/dev/null | grep -q . && { echo "go";         return; }
  find "$dir" -maxdepth 2 -name "*.java" -print -quit 2>/dev/null | grep -q . && { echo "java";       return; }
  find "$dir" -maxdepth 2 -name "*.cs"   -print -quit 2>/dev/null | grep -q . && { echo "csharp";     return; }
  find "$dir" -maxdepth 2 \( -name "*.ts" -o -name "*.tsx" \) -print -quit 2>/dev/null | grep -q . && { echo "typescript"; return; }
  find "$dir" -maxdepth 2 \( -name "*.js" -o -name "*.jsx" \) -print -quit 2>/dev/null | grep -q . && { echo "javascript"; return; }
  echo "unknown"
}

# ── Tool availability check ───────────────────────────────────────────────────
check_tool() {
  command -v "$1" &>/dev/null
}

# ── Run one linter, append output to the shared file ─────────────────────────
run_linter() {
  local lang="$1" dir="$2" label="${3:-}"
  local section_header="${label:-$lang ($dir)}"

  echo ""
  echo "=== $section_header ==="

  case "$lang" in
    python)
      if check_tool ruff; then
        echo "--- ruff ---"
        (cd "$dir" && ruff check . 2>&1) || true
      else
        echo "SKIP: ruff not found (pip install ruff)"
      fi
      if check_tool mypy; then
        echo "--- mypy ---"
        (cd "$dir" && mypy . 2>&1) || true
      fi
      ;;

    typescript|javascript)
      if check_tool npx; then
        echo "--- eslint ---"
        (cd "$dir" && npx --no eslint . --format stylish 2>&1) || true
      else
        echo "SKIP: npx not found"
      fi
      ;;

    go)
      if check_tool golangci-lint; then
        echo "--- golangci-lint ---"
        (cd "$dir" && golangci-lint run ./... 2>&1) || true
      else
        echo "SKIP: golangci-lint not found"
        echo "  Install: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
      fi
      ;;

    java)
      if check_tool mvn; then
        echo "--- checkstyle ---"
        (cd "$dir" && mvn --batch-mode checkstyle:check 2>&1) || true
        echo "--- pmd ---"
        (cd "$dir" && mvn --batch-mode pmd:check 2>&1) || true
      elif check_tool gradle; then
        echo "--- gradle checkstyle ---"
        (cd "$dir" && gradle checkstyleMain --quiet 2>&1) || true
      else
        echo "SKIP: mvn/gradle not found"
      fi
      ;;

    csharp)
      if check_tool dotnet; then
        echo "--- dotnet format ---"
        (cd "$dir" && dotnet format --verify-no-changes --verbosity diagnostic 2>&1) || true
      else
        echo "SKIP: dotnet not found"
      fi
      ;;

    unknown)
      echo "SKIP: could not detect language in $dir"
      ;;

    *)
      echo "SKIP: unsupported language '$lang'"
      ;;
  esac
}

# ── Monorepo package discovery ────────────────────────────────────────────────
# A directory is treated as a "package" if it contains a recognizable manifest
# or if it directly holds source files. Vendor/generated dirs are excluded.
EXCLUDE_DIRS="node_modules|vendor|.git|__pycache__|dist|build|out|target|bin|obj|.venv|venv|env"

discover_packages() {
  local root="$1" max_depth="$2"
  # Find directories containing a manifest file up to max_depth levels
  find "$root" -maxdepth "$max_depth" -type f \
    \( -name "pyproject.toml" -o -name "setup.py" -o -name "go.mod" \
       -o -name "package.json" -o -name "pom.xml" -o -name "build.gradle" \
       -o -name "build.gradle.kts" -o -name "*.csproj" \) \
    2>/dev/null \
    | grep -vE "/($EXCLUDE_DIRS)/" \
    | xargs -I{} dirname {} \
    | sort -u
}

# ── Main ──────────────────────────────────────────────────────────────────────
: > "$OUTPUT_FILE"   # truncate / create

if [[ "$MONOREPO" == true ]]; then
  # ── Monorepo mode ────────────────────────────────────────────────────────
  echo "Mode      : monorepo"
  echo "Root      : $ROOT_TARGET"
  echo "Depth     : $DEPTH"
  echo "Report dir: $REPORT_DIR/"
  echo "Lint out  : $OUTPUT_FILE"
  echo "Report    : $REPORT_FILE"
  echo ""

  mapfile -t PACKAGES < <(discover_packages "$ROOT_TARGET" "$DEPTH") 2>/dev/null \
    || { IFS=$'\n' read -r -d '' -a PACKAGES < <(discover_packages "$ROOT_TARGET" "$DEPTH" && printf '\0') || true; }

  # Fallback for bash < 4 (macOS default ships bash 3)
  if ! declare -p PACKAGES &>/dev/null || [[ ${#PACKAGES[@]} -eq 0 ]]; then
    PACKAGES=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && PACKAGES+=("$line")
    done < <(discover_packages "$ROOT_TARGET" "$DEPTH")
  fi

  if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "No packages found under $ROOT_TARGET at depth $DEPTH."
    echo "Try --depth 3 or run without --monorepo for a single project."
    exit 1
  fi

  echo "Found ${#PACKAGES[@]} package(s):"
  for pkg in "${PACKAGES[@]}"; do
    rel="${pkg#"$ROOT_TARGET/"}"
    detected_lang=$(detect_lang "$pkg")
    echo "  $rel  [$detected_lang]"
  done
  echo ""

  {
    echo "# Monorepo Lint Report"
    echo "# Root: $ROOT_TARGET"
    echo "# Packages: ${#PACKAGES[@]}"
    echo "# Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  } >> "$OUTPUT_FILE"

  for pkg in "${PACKAGES[@]}"; do
    rel="${pkg#"$ROOT_TARGET/"}"
    pkg_lang=$(detect_lang "$pkg")
    echo "Linting  : $rel  [$pkg_lang]"
    run_linter "$pkg_lang" "$pkg" "$rel [$pkg_lang]" >> "$OUTPUT_FILE" 2>&1
  done

else
  # ── Single-project mode ───────────────────────────────────────────────────
  TARGET="$ROOT_TARGET"

  if [[ "$LANG" == "auto" ]]; then
    LANG=$(detect_lang "$TARGET")
    if [[ "$LANG" == "unknown" ]]; then
      echo "ERROR: Could not detect language in $TARGET"
      echo "Use --lang python|typescript|go|java|csharp  or  --monorepo for multi-package repos"
      exit 1
    fi
  fi

  echo "Mode      : single project"
  echo "Language  : $LANG"
  echo "Target    : $TARGET"
  echo "Report dir: $REPORT_DIR/"
  echo "Lint out  : $OUTPUT_FILE"
  echo "Report    : $REPORT_FILE"
  echo ""

  {
    echo "# Lint Report"
    echo "# Language: $LANG"
    echo "# Target: $TARGET"
    echo "# Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    run_linter "$LANG" "$TARGET"
  } 2>&1 | tee "$OUTPUT_FILE"
fi

# ── Summary and LLM instructions ──────────────────────────────────────────────
ISSUE_COUNT=$(grep -c "" "$OUTPUT_FILE" 2>/dev/null || echo 0)

echo ""
echo "────────────────────────────────────────────────────────────────────────"
echo "Lint output → $OUTPUT_FILE  ($ISSUE_COUNT lines)"
echo "Report will → $REPORT_FILE"
echo "────────────────────────────────────────────────────────────────────────"
echo ""
echo "Feed the output to an LLM — the report will be saved to:"
echo "  $REPORT_FILE"
echo ""
echo "  Claude Code"
echo "    claude \"Read $OUTPUT_FILE, analyze it following"
echo "      skills/shared/lint-report-prompt.md, and write the"
echo "      human-readable report to $REPORT_FILE\""
echo ""
echo "  GitHub Copilot (VS Code)"
echo "    1. Open $OUTPUT_FILE in the editor"
echo "    2. In Copilot Chat type:"
echo "       Analyze this lint output, generate a human-readable report,"
echo "       and save it to $REPORT_FILE"
echo ""
echo "  Any LLM / API (pipe + redirect)"
echo "    cat skills/generic/lint-report-system-prompt.txt $OUTPUT_FILE \\"
echo "      | your-llm-cli > $REPORT_FILE"
echo ""
echo "────────────────────────────────────────────────────────────────────────"
