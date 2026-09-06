#!/usr/bin/env bash
set -euo pipefail

target_dir="${HOME}/.local/bin"
if [[ -L "$target_dir/open" ]] && [[ "$(readlink "$target_dir/open")" == "$target_dir/linux-open" ]]; then
    unlink "$target_dir/open"
fi
if [[ -f "$target_dir/linux-open" ]]; then
    unlink "$target_dir/linux-open"
fi
echo "linux-open removed. The system's original /usr/bin/open remains available."
