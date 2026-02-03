# Filename normalization (dates)

Normalize PDF filenames that start with dates into a consistent format:

- `YYYYMMDD_*`
- `YYYY_MM_DD_*`
- `YYYY-MM-DD_*`

→ `YYYY-MM-DD_*`

Examples:
- `20200518_Segundo_alta.pdf`
  → `2020-05-18_Segundo_alta.pdf`

## Behaviour

- Non-destructive: files are only renamed, never overwritten
- Local-only: does not touch Google Drive
- Dry-run by default

## Usage

Dry run (recommended):

```bash
./normalize-names.sh --path /path/to/files

