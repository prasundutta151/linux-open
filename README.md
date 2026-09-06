# linux-open

`linux-open` provides a macOS-like `open` command for Linux with useful routing
for scientific and programming work.

When a requested local file does not exist, `linux-open` creates an empty file
before opening it. It never creates missing parent directories.

- `.tex` and `.ltx` open in **TeXstudio**.
- Source code, text, configuration, Markdown, CSV and other ASCII/UTF-8 files
  open in **Kate**.
- PDF, EPS, PostScript, PNG, JPEG, SVG and other images open in the desktop's
  configured viewer.
- Directories, URLs and unknown binary files use `xdg-open`.

## Install required packages first

`linux-open` itself only needs Python 3.10+ and `xdg-open`. Install Kate and
TeXstudio to obtain the requested code/text and LaTeX routing. A TeX Live
distribution is additionally required if you want TeXstudio to compile LaTeX.

### Ubuntu, Debian and Linux Mint

```bash
sudo apt update
sudo apt install python3 xdg-utils kate texstudio
```

For LaTeX compilation:

```bash
sudo apt install texlive-latex-extra texlive-fonts-recommended texlive-science latexmk biber
```

### Fedora

```bash
sudo dnf install python3 xdg-utils kate texstudio
```

For LaTeX compilation:

```bash
sudo dnf install texlive-scheme-medium latexmk biber
```

### Arch Linux and Manjaro

```bash
sudo pacman -S python xdg-utils kate texstudio
```

For LaTeX compilation:

```bash
sudo pacman -S texlive-basic texlive-latex texlive-latexextra texlive-fontsrecommended latexmk biber
```

### openSUSE

```bash
sudo zypper install python3 xdg-utils kate texstudio
```

For LaTeX compilation:

```bash
sudo zypper install texlive-scheme-medium latexmk biber
```

Package names can vary slightly between distribution releases. The program
falls back to another installed text editor or the desktop default when Kate
or TeXstudio is unavailable.

## Install linux-open

```bash
git clone https://github.com/prasundutta151/linux-open.git
cd linux-open
./install.sh
hash -r
```

The installer places `linux-open` and `open` in `~/.local/bin`. It does not
replace or delete Linux's `/usr/bin/open` command.

## Examples

```bash
open paper.tex
open analysis.py
open notes.txt
open figure.png
open article.pdf
open results.eps
open new-analysis.py       # creates the file, then opens it in Kate
open new-paper.tex         # creates the file, then opens it in TeXstudio
open ~/Documents
open https://www.overleaf.com
```

Open multiple targets:

```bash
open paper.tex figure.png analysis.py
```

Check routing without opening windows:

```bash
open --dry-run paper.tex figure.png analysis.py
```

## Configuration

Override preferred applications with environment variables:

```bash
export LINUX_OPEN_TEX_EDITOR=texstudio
export LINUX_OPEN_TEXT_EDITOR=kate
export LINUX_OPEN_VIEWER=xdg-open
```

## Requirements summary

- Linux and Python 3.10+
- `xdg-open` (normally supplied by `xdg-utils`)
- TeXstudio and Kate for the default routes

Fallback editors are used when TeXstudio or Kate is unavailable.

## Test

```bash
python3 -m unittest discover -s tests -v
```

## Version

1.1.0

## License

MIT
