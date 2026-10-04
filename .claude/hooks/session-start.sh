#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: the same setup CI uses
# (.github/workflows/ci.yml) — the package in .venv with dev extras, ffmpeg for
# video-frames, and libwebp >= 1.5 for video-loop's exact-alpha WebP.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if ! command -v ffmpeg >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y -qq ffmpeg
fi

# Ubuntu's apt ships libwebp 1.3, whose img2webp has no -exact; take the official build.
WEBP=libwebp-1.6.0-linux-x86-64
if ! img2webp -h 2>&1 | grep -q -- -exact; then
  curl -fsSL "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/$WEBP.tar.gz" | tar -xz -C /tmp
  cp /tmp/$WEBP/bin/* /usr/local/bin/
  img2webp -h 2>&1 | grep -q -- -exact
fi

if [ ! -x .venv/bin/python ]; then
  python3 -m venv .venv
fi
.venv/bin/pip install -q -e ".[dev]"

echo "export PATH=\"$CLAUDE_PROJECT_DIR/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
