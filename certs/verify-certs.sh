#!/bin/bash
# Verify the Azure Jenkins certificate chain
CERTS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Certificate Chain Verification — Azure Jenkins ==="
echo ""

# Check files exist
REQUIRED=(
  "root-ca/root-ca.cert.pem"
  "intermediate-ca/intermediate-ca.cert.pem"
  "leaf/jenkins-az.cert.pem"
  "leaf/jenkins-az.chain.pem"
  "ca-bundle.pem"
  "leaf/jenkins-az.pfx"
)

echo "[0] Checking required files..."
ALL_OK=true
for f in "${REQUIRED[@]}"; do
  if [ -f "${CERTS_DIR}/${f}" ]; then
    echo "  ✅ $f"
  else
    echo "  ❌ MISSING: $f"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = false ]; then
  echo ""
  echo "Run: bash certs/generate-certs.sh"
  exit 1
fi

echo ""
echo "[1] Root CA:"
openssl x509 -in "${CERTS_DIR}/root-ca/root-ca.cert.pem" -noout -subject -issuer -dates
echo ""

echo "[2] Intermediate CA:"
openssl x509 -in "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" -noout -subject -issuer -dates
echo ""

echo "[3] Azure Jenkins leaf cert:"
openssl x509 -in "${CERTS_DIR}/leaf/jenkins-az.cert.pem" -noout -subject -issuer -dates -ext subjectAltName
echo ""

echo "[4] Chain trust verification:"
openssl verify \
  -CAfile "${CERTS_DIR}/ca-bundle.pem" \
  "${CERTS_DIR}/leaf/jenkins-az.cert.pem" \
  && echo "  ✅ Chain: OK" || echo "  ❌ Chain: FAILED"

echo ""
echo "[5] PFX integrity check:"
openssl pkcs12 \
  -in "${CERTS_DIR}/leaf/jenkins-az.pfx" \
  -noout \
  -passin pass:pfx_dev_password 2>/dev/null \
  && echo "  ✅ PFX: OK" \
  || echo "  ⚠️  PFX check failed (wrong password? use: PFX_PASS=yourpass bash verify-certs.sh)"

echo ""
echo "=== Verification Complete ==="
