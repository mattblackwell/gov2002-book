#!/usr/bin/env bash
# Render TikZ figures to cropped PDF + PNG and copy the PNG to assets/img.
#
# Usage (from anywhere):
#   tikz/build.sh              # build every tikz/*.tex (except _*.tex)
#   tikz/build.sh foo bar.tex  # build only the named figures
#
# Env vars: DPI (default 300), ENGINE (default pdflatex)

set -euo pipefail

DPI="${DPI:-300}"
ENGINE="${ENGINE:-pdflatex}"
case "$ENGINE" in
  pdflatex) ENGINE_FLAG="-pdf" ;;
  lualatex|xelatex) ENGINE_FLAG="-$ENGINE" ;;
  *) echo "Unsupported ENGINE: $ENGINE" >&2; exit 1 ;;
esac

TIKZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG_DIR="$TIKZ_DIR/../assets/img"
BUILD_DIR="$TIKZ_DIR/build"
mkdir -p "$BUILD_DIR" "$IMG_DIR"

if [ "$#" -gt 0 ]; then
  files=()
  for f in "$@"; do
    f="$(basename "${f%.tex}").tex"
    files+=("$TIKZ_DIR/$f")
  done
else
  shopt -s nullglob
  files=()
  for f in "$TIKZ_DIR"/*.tex; do
    [[ "$(basename "$f")" == _* ]] || files+=("$f")
  done
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "No .tex files to build." >&2
  exit 1
fi

for tex in "${files[@]}"; do
  [ -f "$tex" ] || { echo "Missing: $tex" >&2; exit 1; }
  name="$(basename "$tex" .tex)"
  echo "==> $name"

  latexmk "$ENGINE_FLAG" -interaction=nonstopmode -halt-on-error \
    -outdir="$BUILD_DIR" -cd "$tex" >/dev/null \
    || { echo "LaTeX failed; see $BUILD_DIR/$name.log" >&2; exit 1; }

  # standalone already crops, but pdfcrop guarantees a tight box
  pdfcrop --margins 2 "$BUILD_DIR/$name.pdf" "$BUILD_DIR/$name-crop.pdf" >/dev/null
  pdftoppm -png -r "$DPI" -singlefile "$BUILD_DIR/$name-crop.pdf" "$BUILD_DIR/$name"

  cp "$BUILD_DIR/$name.png" "$IMG_DIR/$name.png"
  echo "    -> assets/img/$name.png"
done
