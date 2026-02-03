#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# CONFIG
# ============================================================
DRY_RUN=1
ROOT="."

# ============================================================
# FLAGS
# ============================================================
for arg in "$@"; do
  case "$arg" in
    --apply)
      DRY_RUN=0
      ;;
    --path=*)
      ROOT="${arg#*=}"
      ;;
    --help|-h)
      cat <<EOF
Usage: normalize-names.sh [options]

Options:
  --dry-run        Show what would be renamed (default)
  --apply          Perform the renaming
  --path=DIR       Root directory to scan (default: current directory)
  --help           Show this help

This script normalizes PDF filenames starting with dates:
  YYYYMMDD_*
  YYYY_MM_DD_*
→ YYYY-MM-DD_*
EOF
      exit 0
      ;;
  esac
done

if [[ ! -d "$ROOT" ]]; then
  echo "❌ Path does not exist: $ROOT"
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "🧪 Dry run mode (no files will be renamed)"
else
  echo "✏️ Apply mode (files will be renamed)"
fi

echo "📂 Scanning: $ROOT"
echo

# ============================================================
# MAIN
# ============================================================
find "$ROOT" -type f -iname "*.pdf" | while read -r file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"

  new_name=""

  # YYYYMMDD_*
  if [[ "$base" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_(.+)\.pdf$ ]]; then
    y="${BASH_REMATCH[1]}"
    m="${BASH_REMATCH[2]}"
    d="${BASH_REMATCH[3]}"
    rest="${BASH_REMATCH[4]}"
    new_name="${y}-${m}-${d}_${rest}.pdf"

  # YYYY_MM_DD_*
  elif [[ "$base" =~ ^([0-9]{4})_([0-9]{2})_([0-9]{2})_(.+)\.pdf$ ]]; then
    y="${BASH_REMATCH[1]}"
    m="${BASH_REMATCH[2]}"
    d="${BASH_REMATCH[3]}"
    rest="${BASH_REMATCH[4]}"
    new_name="${y}-${m}-${d}_${rest}.pdf"
  fi

  # Nothing to do
  if [[ -z "$new_name" || "$new_name" == "$base" ]]; then
    continue
  fi

  target="$dir/$new_name"

  if [[ -e "$target" ]]; then
    echo "⚠️  Skipping (target exists):"
    echo "   $file"
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY] $base"
    echo "      → $new_name"
  else
    mv "$file" "$target"
    echo "✔ Renamed:"
    echo "   $base"
    echo "   → $new_name"
  fi
done

echo
echo "✅ Done."
