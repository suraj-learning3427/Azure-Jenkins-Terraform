#!/bin/bash
# Verify the full certificate chain
CERTS_DIR="$(dirname "$0")"

echo "=== Verifying Certificate Chain ==="
echo ""

echo "[1] Root CA details:"
openssl x509 -in "${CERTS_DIR}/root-ca/root-ca.cert.pem" -noout -subject -issuer -dates
echo ""

echo "[2] Intermediate CA details:"
openssl x509 -in "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" -noout -subject -issuer -dates
echo ""

echo "[3] Azure Jenkins leaf cert details:"
openssl x509 -in "${CERTS_DIR}/leaf/jenkins-az.cert.pem" -noout -subject -issuer -dates -ext subjectAltName
echo ""

echo "[4] GCP Jenkins leaf cert details:"
openssl x509 -in "${CERTS_DIR}/leaf/jenkins-gcp.cert.pem" -noout -subject -issuer -dates -ext subjectAltName
echo ""

echo "[5] Verifying Azure chain trust:"
openssl verify -CAfile "${CERTS_DIR}/ca-bundle.pem" "${CERTS_DIR}/leaf/jenkins-az.cert.pem" \
  && echo "✅ Azure chain: OK" || echo "❌ Azure chain: FAILED"

echo "[6] Verifying GCP chain trust:"
openssl verify -CAfile "${CERTS_DIR}/ca-bundle.pem" "${CERTS_DIR}/leaf/jenkins-gcp.cert.pem" \
  && echo "✅ GCP chain: OK" || echo "❌ GCP chain: FAILED"
