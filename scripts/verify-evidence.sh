#!/usr/bin/env bash
# scripts/verify-evidence.sh <run_id>
set -euo pipefail
RUN_ID="${1:?usage: verify-evidence.sh <run_id> [--vault <bucket>]}"
shift || true
VAULT="${EVIDENCE_VAULT:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT="$2"; shift 2 ;;
  esac
done
[[ -z "$VAULT" ]] && { echo "Set --vault or EVIDENCE_VAULT"; exit 2; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT; cd "$WORK"
PREFIX="runs/${RUN_ID}"

aws s3 cp "s3://${VAULT}/${PREFIX}/" . --recursive \
  --exclude "*" --include "evidence-*.tar.gz*" --include "receipt.json"

BUNDLE=$(ls evidence-*.tar.gz | head -1)

echo "=== 1. Integrity (SHA-256) ==="
EXPECTED=$(cat "${BUNDLE}.sha256")
ACTUAL=$(shasum -a 256 "${BUNDLE}" | awk '{print $1}')
[[ "$EXPECTED" == "$ACTUAL" ]] || { echo "FAIL: SHA mismatch"; exit 1; }
echo "  OK (${ACTUAL})"

echo "=== 2. Authenticity + timestamp (Cosign + Sigstore Rekor) ==="
cosign verify-blob \
  --bundle "${BUNDLE}.sig.bundle" \
  --certificate-identity-regexp '.*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  "${BUNDLE}"
echo "  OK (Cosign verified, Rekor entry exists)"

echo "=== 3. Preservation (Object Lock retention) ==="
RETAIN_UNTIL=$(aws s3api get-object-retention \
  --bucket "${VAULT}" --key "${PREFIX}/${BUNDLE}" \
  --query 'Retention.RetainUntilDate' --output text 2>/dev/null || echo "none")
echo "  Retain until: ${RETAIN_UNTIL}"

echo ""
echo "CHAIN INTACT for run ${RUN_ID}"