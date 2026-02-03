# Filename normalization (dates)

Normalize PDF filenames that start with dates into a consistent format:
- `YYYYMMDD_*`
- `YYYY_MM_DD_*`
- `YYYY-MM-DD_*`

(e.g. `2023-01-15 report.pdf` → `2023-01-15_Report.pdf`).

The script will be:
- non-destructive,
- local-only (never touching Google Drive directly),
- dry-run by default.


