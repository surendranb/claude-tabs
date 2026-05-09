#!/usr/bin/env sh
# install.sh — install claude-tabs into a writable directory on $PATH.
#
# Usage:  curl -fsSL https://raw.githubusercontent.com/surendranb/claude-tabs/main/install.sh | sh
#
# Behaviour: probes $PATH for a writable directory; falls back to ~/.local/bin
# (creates if needed); last-resort sudo into /usr/local/bin. Also verifies
# python3 is available, since claude-tabs needs it.

set -e

REPO="surendranb/claude-tabs"
RAW="https://raw.githubusercontent.com/${REPO}/main/claude-tabs"

# ---- Pre-flight ------------------------------------------------------------
command -v curl    >/dev/null 2>&1 || { echo "error: curl is required"    >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required (claude-tabs is a Python script)" >&2; exit 1; }
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' \
  || { echo "error: python3 >= 3.9 required (you have $(python3 --version 2>&1))" >&2; exit 1; }

# ---- Pick a target directory -----------------------------------------------
target=""
need_sudo=""
need_path=""

# 1) First writable, non-system directory on $PATH.
IFS=:
for dir in $PATH; do
  case "$dir" in
    /sbin|/sbin/*|/usr/sbin|/usr/sbin/*|/bin|/bin/*|/usr/bin|/usr/bin/*) continue ;;
  esac
  if [ -d "$dir" ] && [ -w "$dir" ]; then
    target="$dir"
    break
  fi
done
unset IFS

# 2) Otherwise create / use ~/.local/bin (no sudo). Note if not on PATH.
if [ -z "$target" ]; then
  if mkdir -p "$HOME/.local/bin" 2>/dev/null && [ -w "$HOME/.local/bin" ]; then
    target="$HOME/.local/bin"
    case ":$PATH:" in
      *":$target:"*) ;;
      *) need_path=1 ;;
    esac
  fi
fi

# 3) Last resort — sudo into /usr/local/bin (always on macOS PATH).
if [ -z "$target" ]; then
  target="/usr/local/bin"
  need_sudo=1
fi

# ---- Download + install ----------------------------------------------------
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

echo "downloading claude-tabs..."
curl -fsSL "$RAW" -o "$tmp"

echo "installing to $target/claude-tabs"
if [ "$need_sudo" = "1" ]; then
  sudo cp "$tmp" "$target/claude-tabs"
  sudo chmod +x "$target/claude-tabs"
else
  cp "$tmp" "$target/claude-tabs"
  chmod +x "$target/claude-tabs"
fi

# ---- Verify + next steps ---------------------------------------------------
if "$target/claude-tabs" --help >/dev/null 2>&1; then
  echo "installed: $target/claude-tabs"
else
  echo "warning: installed but --help failed; check that python3 is on PATH" >&2
fi

if [ "$need_path" = "1" ]; then
  echo
  echo "note: $target is not on your \$PATH. Add to your shell profile:"
  echo "    export PATH=\"$target:\$PATH\""
fi

echo
echo "try:  claude-tabs --help"
