# autodeskew

This script downloads PDFs from a selected Google Drive folder, applies:
- deskew (rotation correction),
- optional OCR,
- and uploads the processed files back to Drive,

while being reasonably **safe, resumable, and automation-friendly**.

This was originally built to clean up large batches of scanned medical documents,
but it should work for any PDF collection.

## ✨ Features

- 📂 Select a Google Drive folder interactively (using `fzf`)
- ⬇️ Download PDFs recursively via `rclone`
- 🛠 Deskew scanned PDFs using ImageMagick
- 🔎 Run OCR on processed PDFs (via `ocrmypdf`)
- 🔒 Configurable behaviour for encrypted PDFs (`skip`, `fail`, `ask`)
- ♻️ Idempotent: already processed files are skipped unless forced
- ⚠️ Optional `--force` mode to reprocess everything

## 🧩 Requirements

Make sure the following tools are installed:

- **[bash](https://www.gnu.org/software/bash/)** (≥ 4.x recommended)
- **[rclone](https://rclone.org/)** (configured with a `gdrive:` remote)
- **[ImageMagick](https://imagemagick.org/)** (the `magick` command)
- **[ocrmypdf](https://ocrmypdf.readthedocs.io/)**
- **[pdfinfo](https://poppler.freedesktop.org/)** (from `poppler-utils`)
- **[fzf](https://github.com/junegunn/fzf)**

## 📦 Installation

### On Debian / Ubuntu (example)

```bash
sudo apt install rclone imagemagick ocrmypdf poppler-utils fzf
```

Make sure `rclone` is configured and that you have a `gdrive:` remote pointing to your Google Drive.

## 🚀 Usage

Make the script executable:

```bash
chmod +x autodeskew_drive_docs.sh
```

Run the script:
```bash
./autodeskew_drive_docs.sh
```

## ⚙️ Optional flags

- `--force`  
  Reprocess all PDFs, even if a processed version already exists locally.

- `--on-encrypted=MODE`  
  Defines how encrypted PDFs are handled. Possible values:
  - `skip` (default): copy the original PDF without processing
  - `fail`: abort the whole run if an encrypted PDF is found
  - `ask`: prompt for a password and try to process the PDF

## 🔁 How it works

1. Prompts you to select a Google Drive folder (owned by you or shared with you).
2. Downloads all PDFs recursively using `rclone`.
3. Applies deskew (rotation correction) using ImageMagick.
4. Optionally runs OCR on the processed PDFs.
5. Uploads the results back to Google Drive into a `(fixed)` sibling folder.

## 🔁 Idempotency and safety

- Already processed PDFs are skipped by default.
- The script can be safely re-run multiple times.
- Use `--force` if you want to start from scratch.

## 🤔 Why this exists

This tool was built to automate the cleanup of large batches of scanned PDFs
stored in Google Drive, with a focus on:

- reproducibility,
- safety (no destructive operations),
- and the ability to re-run the process as many times as needed.

It intentionally favors simple, composable Unix tools over a monolithic solution.

## ⚠️ Known limitations

- This is a local, client-side tool; it is not a Google Drive plugin.
- Processing very large PDFs can be slow and memory-intensive.
- Encrypted PDFs can only be processed if a valid password is provided.
- The script assumes a Unix-like environment and has only been tested on Linux.

## 📝 Notes

This is a pragmatic, personal tool that grew out of a real workflow.
If you find it useful, feel free to adapt it to your own needs.

