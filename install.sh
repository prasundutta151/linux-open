#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${HOME}/.local/bin"

command -v python3 >/dev/null || { echo "Error: Python 3 is required." >&2; exit 1; }
python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' || {
    echo "Error: Python 3.10 or newer is required." >&2
    exit 1
}
command -v xdg-open >/dev/null || { echo "Error: xdg-utils is required." >&2; exit 1; }
command -v kate >/dev/null || echo "Warning: Kate is absent; text files will use a fallback application."
command -v texstudio >/dev/null || echo "Warning: TeXstudio is absent; TeX files will use a fallback application."

mkdir -p "$target_dir"
install -m 0755 "$source_dir/bin/linux-open" "$target_dir/linux-open"
ln -sfn "$target_dir/linux-open" "$target_dir/open"

echo "linux-open 1.1.0 installed."
echo "  open       -> $target_dir/linux-open"
echo "  linux-open -> $target_dir/linux-open"
echo "Run 'hash -r' once if this terminal previously cached /usr/bin/open."
