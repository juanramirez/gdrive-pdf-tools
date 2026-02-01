# gdrive-pdf-tools

A Bash script to process PDFs from Google Drive folders you own or that are shared with you:
- recursively download PDFs,
- automatically deskew scanned documents,
- run OCR,
- and upload the processed PDFs back to Google Drive.

Designed for personal workflows (e.g. scanned medical or administrative documents) with an emphasis on **robustness, reproducibility, and auditability**.

---

## ✨ Features

- 📂 Interactive selection of Google Drive folders (owned or shared)
- 🛠 Automatic deskew using ImageMagick
- 🔎 OCR via `ocrmypdf`
- 🔒 Configurable handling of encrypted PDFs (`skip | fail | ask`)
- ♻️ `--force` mode to reprocess everything from scratch
- 📊 Download and upload logs via `rclone`
- 🧼 Defensive Bash scripting (`set -euo pipefail`, validation, shellcheck-clean)

---

## 🧩 Requirements

Make sure the following tools are installed:

- **bash** (≥ 4.x)
- **rclone** (configured with Google Drive)
- **ImageMagick** (`magick`)
- **ocrmypdf**
- **poppler-utils** (`pdfinfo`)
- **fzf**

On Debian/Ubuntu (indicative):

```bash
sudo apt install rclone imagemagick ocrmypdf poppler-utils fzf

