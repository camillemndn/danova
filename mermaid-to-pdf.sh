#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -euo pipefail

qmd="${QUARTO_PROJECT_INPUT_FILES:-index.qmd}"
mmd_dir="_cache/mermaid"
mkdir -p "$mmd_dir"

# Extract each labeled mermaid block, write to a .mmd in cache, render to PDF
awk '
  /^```\{mermaid\}/ { in_block=1; label=""; body=""; next }
  in_block && /^%%\| label:/ { label=$3; next }
  in_block && /^%%\|/ { next }
  in_block && /^```$/ {
    if (label != "") {
      file = mmd_dir "/" label ".mmd"
      printf "%s", body > file
    }
    in_block=0; next
  }
  in_block { body = body $0 "\n" }
' mmd_dir="$mmd_dir" "$qmd"

# Render all generated .mmd files to PDF
for mmd in "$mmd_dir"/*.mmd; do
  [[ -f "$mmd" ]] || continue
  label="$(basename "${mmd%.mmd}")"
  mmdc -i "$mmd" --outputFormat=pdf --pdfFit -o "${label}.pdf"
done
