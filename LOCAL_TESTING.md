# Local testing for Sheets to RO-Crate sync

This repository includes one shared script used by both local runs and GitHub Actions:

- scripts/sync-ro-crate-from-sheets.sh

## 1) Direct local run (fastest)

Prerequisites:

- git
- curl
- node and npm (if using the default npx command)
- ro-crate-excel available via npx or your custom command

From repo root:

```bash
export GOOGLE_SHEET_EXPORT_URL='https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=xlsx&gid=0'
export SHEET_FILE='data/source.xlsx'
export RO_CRATE_OUTPUT_PATH='ro-crate'
export RO_CRATE_EXCEL_COMMAND='npx ro-crate-excel "$SHEET_FILE" "$RO_CRATE_OUTPUT_PATH"'

# test conversion only (no commit)
bash scripts/sync-ro-crate-from-sheets.sh

# test conversion + local commit (no push)
AUTO_COMMIT=true AUTO_PUSH=false bash scripts/sync-ro-crate-from-sheets.sh
```

If you want to push automatically during local test:

```bash
AUTO_COMMIT=true AUTO_PUSH=true bash scripts/sync-ro-crate-from-sheets.sh
```

## 2) Run the GitHub Action locally with act (optional)

Install act: https://github.com/nektos/act
-- on mac with Homebrew:
`brew install act`

Create a local secrets file named .secrets.act:

```bash
GOOGLE_SHEET_EXPORT_URL=https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=xlsx&gid=0
```

Run the workflow_dispatch event:

```bash
act workflow_dispatch -W .github/workflows/sync-ro-crate-from-sheets.yml --secret-file .secrets.act
```

Note:

- act runs in Docker and simulates Actions, but behavior can differ slightly from GitHub-hosted runners.
- If your sheet requires auth beyond a public/exportable URL, add authenticated download logic first.
