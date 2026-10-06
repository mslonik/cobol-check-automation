#!/usr/bin/env bash
set -euo pipefail

: "${ZOWE_USERNAME:?ZOWE_USERNAME must be set}"
: "${ZOWE_PASSWORD:?ZOWE_PASSWORD must be set}"
: "${ZOWE_HOST:?ZOWE_HOST must be set}"
ZOWE_PORT="${ZOWE_PORT:-443}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${COBOLCHECK_DIR:-}" ]]; then
  if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    COBOLCHECK_DIR="${GITHUB_WORKSPACE}/COBOLcheck"
  else
    COBOLCHECK_DIR="${SCRIPT_DIR}/../../COBOLcheck"
  fi
fi

if ! command -v zowe >/dev/null 2>&1; then
  echo "Zowe CLI is not installed or not available on PATH" >&2
  exit 1
fi

if [[ ! -d "$COBOLCHECK_DIR" ]]; then
  echo "COBOLcheck source directory not found: $COBOLCHECK_DIR" >&2
  exit 1
fi

COBOLCHECK_DIR="$(cd -- "$COBOLCHECK_DIR" && pwd)"

LOWERCASE_USERNAME="$(printf '%s' "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')"
REMOTE_DIR="/z/${LOWERCASE_USERNAME}/cobolcheck"
ZOWE_CONNECTION=(--host "$ZOWE_HOST" --port "$ZOWE_PORT" --user "$ZOWE_USERNAME" --password "$ZOWE_PASSWORD")

if ! zowe zos-files list uss-files "$REMOTE_DIR" "${ZOWE_CONNECTION[@]}" >/dev/null 2>&1; then
  echo "Directory does not exist. Creating it..."
  zowe zos-files create uss-directory "$REMOTE_DIR" "${ZOWE_CONNECTION[@]}"
else
  echo "Directory already exists."
fi

zowe zos-files upload dir-to-uss "$COBOLCHECK_DIR" "$REMOTE_DIR" \
  --recursive \
  --binary-files "cobol-check-0.2.19.jar" \
  "${ZOWE_CONNECTION[@]}"

echo "Verifying upload:"
zowe zos-files list uss-files "$REMOTE_DIR" "${ZOWE_CONNECTION[@]}"
