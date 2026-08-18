#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GOOGLE_SHEET_EXPORT_URL:-}" ]; then
  echo "Missing required environment variable: GOOGLE_SHEET_EXPORT_URL"
  exit 1
fi

SHEET_FILE="data/ro-crate-metadata-tools.xlsx"
RO_CRATE_OUTPUT_PATH="ro-crate"
RO_CRATE_EXCEL_COMMAND="${RO_CRATE_EXCEL_COMMAND:-}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-chore(ro-crate): sync from Google Sheets}"
AUTO_COMMIT="${AUTO_COMMIT:-false}"
AUTO_PUSH="${AUTO_PUSH:-false}"
GIT_USER_NAME="${GIT_USER_NAME:-github-actions[bot]}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$RO_CRATE_OUTPUT_PATH" = /* ]]; then
  RO_CRATE_OUTPUT_ABS="$RO_CRATE_OUTPUT_PATH"
else
  RO_CRATE_OUTPUT_ABS="$REPO_ROOT/$RO_CRATE_OUTPUT_PATH"
fi

echo "Downloading spreadsheet to $SHEET_FILE"
mkdir -p "$(dirname "$SHEET_FILE")"

download_file() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GOOGLE_SHEET_EXPORT_URL" -o "$SHEET_FILE"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SHEET_FILE" "$GOOGLE_SHEET_EXPORT_URL"
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$GOOGLE_SHEET_EXPORT_URL" "$SHEET_FILE" <<'PY'
import pathlib
import sys
import urllib.request

url = sys.argv[1]
target = pathlib.Path(sys.argv[2])

with urllib.request.urlopen(url) as response:
    target.write_bytes(response.read())
PY
    return
  fi

  echo "No supported download tool found. Install curl, wget, or python3."
  exit 1
}

download_file
test -s "$SHEET_FILE"

echo "Working directory before conversion: $(pwd)"
echo "RO-Crate output path: $RO_CRATE_OUTPUT_ABS"
mkdir -p "$RO_CRATE_OUTPUT_ABS"

if ! command -v sf >/dev/null 2>&1; then
  echo "Missing required runtime dependency: sf (Siegfried)."
  echo "In GitHub Actions/act, this is installed by the workflow step."
  echo "For direct local script runs, install sf first."
  exit 1
fi

if [ -x ./node_modules/.bin/rocxl ]; then
  RO_CRATE_EXCEL_COMMAND="${RO_CRATE_EXCEL_COMMAND:-./node_modules/.bin/rocxl \"$SHEET_FILE\" \"$RO_CRATE_OUTPUT_ABS\"}"
elif [ -x ./node_modules/.bin/ro-crate-excel ]; then
  RO_CRATE_EXCEL_COMMAND="${RO_CRATE_EXCEL_COMMAND:-./node_modules/.bin/ro-crate-excel \"$SHEET_FILE\" \"$RO_CRATE_OUTPUT_ABS\"}"
else
  echo "Missing local RO-Crate converter binary."
  echo "Install one of these packages in the repo: npm install --no-save rocxl"
  echo "or: npm install --no-save ro-crate-excel"
  exit 1
fi

echo "Generating RO-Crate using ro-crate-excel"
eval "$RO_CRATE_EXCEL_COMMAND"

echo "Working directory after conversion: $(pwd)"

if [ -d "$RO_CRATE_OUTPUT_ABS" ]; then
  echo "RO-Crate generated at: $RO_CRATE_OUTPUT_ABS"
  find "$RO_CRATE_OUTPUT_ABS" -maxdepth 2 -print | sort
else
  echo "RO-Crate output path does not exist: $RO_CRATE_OUTPUT_ABS"
  exit 1
fi

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
