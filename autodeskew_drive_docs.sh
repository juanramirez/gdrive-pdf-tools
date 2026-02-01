#!/usr/bin/env bash
set -euo pipefail

# =====================
# CONFIG
# =====================
DENSITY=200
DESKEW="40%"
OCR_LANG="spa"

BASE="$HOME/tmp_medical_reports"
TMP="$BASE"
ORIG="$BASE/originals"
FIXED="$BASE/fixed"

# =====================
# CLI ARGUMENTS
# =====================
FORCE = 0

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=1
      ;;
    --on-encripted=*)
      ON_ENCRYPTED="${arg#*=}"
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      exit 1
      ;;
  esac
done

# =====================
# ENCRYPTED PDFS BEHAVIOUR
# =====================
ON_ENCRYPTED="skip"   # skip | fail | ask

for arg in "$@"; do
  case "$arg" in
    --on-encrypted=*)
      ON_ENCRYPTED="${arg#*=}"
      ;;
  esac
done

if [[ ! "$ON_ENCRYPTED" =~ ^(skip|fail|ask)$ ]]; then
  echo "❌ Invalid value for --on-encrypted. Use skip|fail|ask"
  exit 1
fi

# =====================
# FORCE MODE
# =====================
FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
  echo "⚠️ FORCE mode enabled: all PDFs will be reprocessed"
fi

# =====================
# SELECT SOURCE FOLDER
# =====================
echo "📂 Select source folder (shared with you):"
SRC_FOLDER=$(
  rclone lsf gdrive: \
    --dirs-only \
    --drive-shared-with-me |
  sed 's:/$::' |
  fzf --prompt="Select folder: "
)

if [[ -z "$SRC_FOLDER" ]]; then
  echo "❌ No folder selected. Aborting."
  exit 1
fi

SRC="gdrive:$SRC_FOLDER"
DST="gdrive:$SRC_FOLDER (fixed)"

echo "✔ Selected: $SRC_FOLDER"
echo "📁 Destination: $SRC_FOLDER (fixed)"

# =====================
# CLEAN LOCAL STATE
# =====================
if [[ $FORCE -eq 1 ]]; then
  echo "🧹 Force mode: removing previous local data..."
  rm -rf "$BASE"
fi

# recrear siempre
mkdir -p "$TMP" "$ORIG/$SRC_FOLDER" "$FIXED/$SRC_FOLDER"

# =====================
# DOWNLOAD PDFs (RECURSIVE)
# =====================
echo "⬇ Downloading PDFs..."
rclone copy "$SRC" "$ORIG/$SRC_FOLDER" \
  --drive-shared-with-me \
  --progress \
  --log-file="$TMP/rclone_download.log" \
  --log-level INFO

# =====================
# DESKEW (BULLETPROOF)
# =====================
echo "🛠 Deskewing PDFs (bulletproof)..."

export MAGICK_MEMORY_LIMIT=512MiB
export MAGICK_MAP_LIMIT=1GiB
export MAGICK_DISK_LIMIT=4GiB

mapfile -t PDFS < <(
  find "$ORIG/$SRC_FOLDER" -type f -iname "*.pdf"
)

for f in "${PDFS[@]}"; do
  rel="${f#$ORIG/$SRC_FOLDER/}"
  out="$FIXED/$SRC_FOLDER/$rel"
  mkdir -p "$(dirname "$out")"

  if [[ $FORCE -eq 0 && -f "$out" ]]; then
    continue
  fi

  if pdfinfo "$f" 2>/dev/null | grep -q "Encrypted: yes"; then
  case "$ENCRYPTED_MODE" in
    skip)
      echo "🔒 Encrypted, skipped: $rel"
      cp -n "$f" "$out"
      continue
      ;;

    fail)
      echo "❌ Encrypted PDF found, aborting: $rel"
      exit 2
      ;;

    ask)
      echo "🔐 Encrypted PDF: $rel"
      read -s -p "Password: " PDF_PASS
      echo

      if ! magick \
        -define pdf:password="$PDF_PASS" \
        -limit memory 512MiB \
        -limit map 1GiB \
        -limit disk 4GiB \
        -density 200 \
        "$f" \
        -deskew 40% \
        "$out"; then
        echo "⚠️ Wrong password or failed, copying original"
        cp -n "$f" "$out"
      fi
      continue
      ;;
  esac
  fi

  echo "  → Deskew: $rel"

  if ! magick \
      -limit memory 512MiB \
      -limit map 1GiB \
      -limit disk 4GiB \
      -density 200 \
      "$f" \
      -deskew 40% \
      -quality 100 \
      "$out"; then
    echo "⚠️ Deskew failed, copying original: $rel"
    cp -n "$f" "$out"
  fi
done

# =====================
# OCR (ONLY FIXED PDFs)
# =====================
echo "🔎 OCR (Spanish)..."

mapfile -t PDFS_FIXED < <(
  find "$FIXED/$SRC_FOLDER" -type f -iname "*.pdf"
)

if [[ ${#PDFS_FIXED[@]} -eq 0 ]]; then
  echo "📄 No PDFs to OCR."
else
  for f in "${PDFS_FIXED[@]}"; do
    tmp="${f%.pdf}.ocr.pdf"
    echo "  → OCR: ${f#$FIXED/$SRC_FOLDER/}"
    ocrmypdf --skip-text --language "$OCR_LANG" "$f" "$tmp"
    mv "$tmp" "$f"
  done
fi

# =====================
# ENSURE DESTINATION
# =====================
echo "📁 Ensuring destination folder exists..."
rclone mkdir "$DST" || true

# =====================
# UPLOAD PROCESSED FILES
# =====================
echo "⬆ Uploading processed PDFs..."
rclone copy "$FIXED/$SRC_FOLDER" "$DST" \
  --progress \
  --log-file="$TMP/rclone_upload.log" \
  --log-level INFO

echo "✅ Done."

