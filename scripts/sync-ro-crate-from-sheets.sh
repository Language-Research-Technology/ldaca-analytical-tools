#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GOOGLE_SHEET_EXPORT_URL:-}" ]; then
  echo "Missing required environment variable: GOOGLE_SHEET_EXPORT_URL"
  exit 1
fi

SHEET_FILE="${SHEET_FILE:-data/source.xlsx}"
RO_CRATE_OUTPUT_PATH="${RO_CRATE_OUTPUT_PATH:-ro-crate}"
RO_CRATE_EXCEL_COMMAND="${RO_CRATE_EXCEL_COMMAND:-npx ro-crate-excel \"$SHEET_FILE\" \"$RO_CRATE_OUTPUT_PATH\"}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-chore(ro-crate): sync from Google Sheets}"
AUTO_COMMIT="${AUTO_COMMIT:-false}"
AUTO_PUSH="${AUTO_PUSH:-false}"
GIT_USER_NAME="${GIT_USER_NAME:-github-actions[bot]}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

echo "Downloading spreadsheet to $SHEET_FILE"
mkdir -p "$(dirname "$SHEET_FILE")"
curl -fsSL "$GOOGLE_SHEET_EXPORT_URL" -o "$SHEET_FILE"
test -s "$SHEET_FILE"

echo "Generating RO-Crate using ro-crate-excel"
eval "$RO_CRATE_EXCEL_COMMAND"

if [ "$AUTO_COMMIT" != "true" ]; then
  echo "AUTO_COMMIT is not true, skipping git commit"
  exit 0
fi

git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

git add -A "$RO_CRATE_OUTPUT_PATH" || true

if git diff --cached --quiet; then
  echo "No RO-Crate changes to commit"
  exit 0
fi

git commit -m "$COMMIT_MESSAGE"

if [ "$AUTO_PUSH" = "true" ]; then
  git push
else
  echo "AUTO_PUSH is not true, commit created locally without pushing"
fi
