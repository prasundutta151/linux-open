#!/usr/bin/env bash
set -euo pipefail

version="1.2.0"
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${HOME}/.local/bin"
with_dependencies=0
check_only=0
force=0

usage() {
    cat <<'EOF'
linux-open installer 1.2.0

Usage:
  ./install.sh                     Check dependencies and install linux-open
  ./install.sh --with-dependencies Install missing packages, then linux-open
  ./install.sh --check             Only report dependencies and conflicts

Options:
  --with-dependencies  Install all missing recommended dependencies using the
                       detected distribution package manager (sudo required).
  --check              Run preflight checks without changing anything.
  --force              Replace a conflicting ~/.local/bin/open file.
  -h, --help           Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --with-dependencies) with_dependencies=1 ;;
        --check) check_only=1 ;;
        --force) force=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: unknown installer option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

commands=(python3 xdg-open kate texstudio pdflatex xelatex lualatex latexmk biber evince eog)
labels=(
    "Core runtime" "Desktop/default viewer" "Code and text editor"
    "LaTeX editor" "PDFLaTeX compiler" "XeLaTeX compiler" "LuaLaTeX compiler"
    "Automated LaTeX builder" "Bibliography processor" "PDF/EPS viewer" "Image viewer"
)

missing_commands=()
echo "linux-open $version dependency preflight"
echo "------------------------------------------------------------------------"
printf '%-12s %-10s %s\n' "COMMAND" "STATUS" "PURPOSE / LOCATION"
printf '%-12s %-10s %s\n' "------------" "----------" "------------------------------"
for index in "${!commands[@]}"; do
    command_name="${commands[$index]}"
    if location="$(command -v "$command_name" 2>/dev/null)"; then
        printf '%-12s %-10s %s — %s\n' "$command_name" "AVAILABLE" "${labels[$index]}" "$location"
    else
        printf '%-12s %-10s %s\n' "$command_name" "MISSING" "${labels[$index]}"
        missing_commands+=("$command_name")
    fi
done
echo "------------------------------------------------------------------------"

package_manager=""
packages=()
if command -v apt-get >/dev/null 2>&1; then
    package_manager="apt"
    packages=(python3 xdg-utils kate texstudio texlive-latex-extra texlive-fonts-recommended texlive-science texlive-xetex texlive-luatex latexmk biber evince eog)
elif command -v dnf >/dev/null 2>&1; then
    package_manager="dnf"
    packages=(python3 xdg-utils kate texstudio texlive-scheme-medium latexmk biber evince eog)
elif command -v pacman >/dev/null 2>&1; then
    package_manager="pacman"
    packages=(python xdg-utils kate texstudio texlive-basic texlive-latex texlive-latexextra texlive-fontsrecommended latexmk biber evince eog)
elif command -v zypper >/dev/null 2>&1; then
    package_manager="zypper"
    packages=(python3 xdg-utils kate texstudio texlive-scheme-medium latexmk biber evince eog)
fi

install_command=""
case "$package_manager" in
    apt) install_command="sudo apt update && sudo apt install ${packages[*]}" ;;
    dnf) install_command="sudo dnf install ${packages[*]}" ;;
    pacman) install_command="sudo pacman -S ${packages[*]}" ;;
    zypper) install_command="sudo zypper install ${packages[*]}" ;;
esac

if ((${#missing_commands[@]})); then
    echo "Missing commands: ${missing_commands[*]}"
    if [[ -n "$install_command" ]]; then
        echo "Install all dependencies with:"
        echo "  ./install.sh --with-dependencies"
        echo "Equivalent package command:"
        echo "  $install_command"
    else
        echo "No supported package manager was detected; install missing commands manually."
    fi
else
    echo "All recommended commands are available."
fi

echo
echo "Command conflict check"
echo "------------------------------------------------------------------------"
conflict=0
system_open="$(command -v open 2>/dev/null || true)"
local_open="$target_dir/open"
if [[ -e "$local_open" || -L "$local_open" ]]; then
    if [[ -L "$local_open" ]] && [[ "$(readlink "$local_open")" == "$target_dir/linux-open" ]]; then
        echo "UPGRADE:  $local_open already belongs to linux-open."
    else
        echo "CONFLICT: $local_open exists and is not managed by linux-open."
        echo "          Use --force only if you intend to replace it."
        conflict=1
    fi
elif [[ -n "$system_open" ]]; then
    echo "EXPECTED: $system_open is the distribution's original open command."
    echo "          linux-open shadows it through ~/.local/bin but does not modify it."
else
    echo "NONE:     No existing open command was found."
fi
if [[ -e "$target_dir/linux-open" ]] && ! cmp -s "$source_dir/bin/linux-open" "$target_dir/linux-open"; then
    echo "UPGRADE:  Existing linux-open will be updated to version $version."
fi

if [[ "$package_manager" == "apt" ]] && ((${#missing_commands[@]})); then
    echo
    echo "APT package conflict simulation"
    echo "------------------------------------------------------------------------"
    simulation="$(apt-get -s install "${packages[@]}" 2>&1)" || {
        echo "CONFLICT: APT cannot resolve the dependency transaction:"
        echo "$simulation" | tail -n 12
        conflict=1
    }
    if grep -q '^Remv ' <<<"$simulation"; then
        echo "WARNING: APT proposes removing installed packages:"
        grep '^Remv ' <<<"$simulation"
        conflict=1
    elif ((conflict == 0)); then
        echo "No package removals or broken dependency conflicts detected."
    fi
fi

if ((check_only)); then
    ((conflict == 0)) || exit 1
    exit 0
fi
if ((conflict)) && ((force == 0)); then
    echo "Installation stopped because conflicts were detected." >&2
    exit 1
fi

if ((with_dependencies)) && ((${#missing_commands[@]})); then
    case "$package_manager" in
        apt)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf) sudo dnf install -y "${packages[@]}" ;;
        pacman) sudo pacman -S --needed "${packages[@]}" ;;
        zypper) sudo zypper --non-interactive install "${packages[@]}" ;;
        *) echo "Cannot install dependencies automatically on this distribution." >&2; exit 1 ;;
    esac
fi

command -v python3 >/dev/null || { echo "Error: Python 3 is required." >&2; exit 1; }
python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' || {
    echo "Error: Python 3.10 or newer is required." >&2
    exit 1
}
command -v xdg-open >/dev/null || { echo "Error: xdg-utils is required; use --with-dependencies." >&2; exit 1; }

mkdir -p "$target_dir"
install -m 0755 "$source_dir/bin/linux-open" "$target_dir/linux-open"
ln -sfn "$target_dir/linux-open" "$target_dir/open"

echo
echo "linux-open $version installed."
echo "  open       -> $target_dir/linux-open"
echo "  linux-open -> $target_dir/linux-open"
echo "Run 'hash -r' once if this terminal previously cached another open command."
