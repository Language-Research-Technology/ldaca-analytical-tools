# LDaCA Analytical Tools Google Sheets to RO-Crate Sync

This repository includes a workflow and script that:

1. Downloads an Excel file exported from Google Sheets.
2. Places it in the crate folder as ro-crate-metadata.xlsx.
3. Runs rocxl against the RO-Crate directory to update metadata.
4. Commits and pushes generated changes.

## Files

- Workflow: .github/workflows/sync-ro-crate-from-sheets.yml
- Script: scripts/sync-ro-crate-from-sheets.sh

## Runtime Flow

The script currently uses these fixed paths:

- Downloaded spreadsheet: data/ro-crate-metadata-tools.xlsx
- RO-Crate directory: ro-crate
- Spreadsheet used by rocxl: ro-crate/ro-crate-metadata.xlsx

Then it runs:

    rocxl ro-crate

(Using the local CLI from node_modules/.bin.)

## What To Configure In GitHub

Set the repository secret used by the workflow:

1. Open your repository on GitHub.
2. Go to Settings.
3. Go to Secrets and variables > Actions.
4. Under Repository secrets, add or update:
   - Name: GOOGLE_SHEET_EXPORT_URL
    - Value: your Google Sheets export URL (xlsx format)

Example export URL format:

https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=xlsx

## Run In GitHub (Manual)

The workflow is manual (workflow_dispatch).

1. Open the Actions tab.
2. Select Sync RO-Crate from Google Sheets.
3. Click Run workflow.

## Run Locally With act

Prerequisites:

- Docker
- act
- A local secret file at .secrets.act with GOOGLE_SHEET_EXPORT_URL

Example .secrets.act:

    GOOGLE_SHEET_EXPORT_URL=https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=xlsx&gid=0

Run:

    act workflow_dispatch -W .github/workflows/sync-ro-crate-from-sheets.yml --secret-file .secrets.act

## Run Script Directly (Without GitHub Actions)

Prerequisites:

- Node and npm
- sf available on PATH
- GOOGLE_SHEET_EXPORT_URL set in the shell

Install converter CLI:

    npm install --no-save ro-crate-excel

Run:

    bash scripts/sync-ro-crate-from-sheets.sh

## Optional Workflow Edits

Edit these env values in .github/workflows/sync-ro-crate-from-sheets.yml if needed:

- COMMIT_MESSAGE
- AUTO_COMMIT
- AUTO_PUSH
- RO_CRATE_EXCEL_COMMAND (advanced override)

## Notes

- The workflow bootstraps Siegfried data from GitHub release artifacts (instead of sf -update).
- The script stages only the ro-crate directory for commit.
