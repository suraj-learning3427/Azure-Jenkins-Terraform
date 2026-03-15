#!/bin/bash
# Full Certificate Chain Generator
# Root CA → Intermediate CA → Leaf Certs (Azure + GCP Jenkins)
# Run this ONCE locally, then store outputs in Key Vault / Secret Manager

set -e

DOMAIN="internal.company"
AZURE_JENKINS_DNS="jenkins-az.${DOMAIN}"
GCP_JENKINS_DNS="jenkins-gcp.${DOMAIN}"
CERTS_DIR="$(dirname "$0")"

echo "================================================"
echo " Generating Full Certificate Chain"
echo " Root CA → Intermediate CA → Leaf Certs"
echo "================================================"

mkdir -p "${CERTS_DIR}/root-ca"
mkdir -p "${CERTS_DIR}/intermediate-ca"
mkdir -p "${CERTS_DIR}/leaf"
mkdir -p "${CERTS_DIR}/root-ca/newcerts"
mkdir -p "${CERTS_DIR}/intermediate-ca/newcerts"

touch "${CERTS_DIR}/root-ca/index.txt"
touch "${CERTS_DIR}/intermediate-ca/index.txt"
echo "1000" > "${CERTS_DIR}/root-ca/serial"
echo "2000" > "${CERTS_DIR}/intermediate-ca/serial"

# ─── STEP 1: ROOT CA ──────────────────────────────────────────────────────────
echo ""
echo "[1/5] Generating Root CA private key..."
openssl genrsa -aes256 \
  -passout pass:rootca_password_change_me \
  -out "${CERTS_DIR}/root-ca/root-ca.key.pem" 4096

echo "[1/5] Generating Root CA certificate (10 years)..."
openssl req -new -x509 \
  -key "${CERTS_DIR}/root-ca/root-ca.key.pem" \
  -passin pass:rootca_password_change_me \
  -out "${CERTS_DIR}/root-ca/root-ca.cert.pem" \
  -days 3650 \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=MyOrg Root CA" \
  -extensions v3_ca \
  -config <(cat <<EOF
[ req ]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
prompt             = no

[ req_distinguished_name ]
C  = US
ST = State
L  = City
O  = MyOrg
OU = IT
CN = MyOrg Root CA

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
EOF
)

echo "✅ Root CA created: root-ca/root-ca.cert.pem"

# ─── STEP 2: INTERMEDIATE CA ──────────────────────────────────────────────────
echo ""
echo "[2/5] Generating Intermediate CA private key..."
openssl genrsa -aes256 \
  -passout pass:intermediateca_password_change_me \
  -out "${CERTS_DIR}/intermediate-ca/intermediate-ca.key.pem" 4096

echo "[2/5] Generating Intermediate CA CSR..."
openssl req -new \
  -key "${CERTS_DIR}/intermediate-ca/intermediate-ca.key.pem" \
  -passin pass:intermediateca_password_change_me \
  -out "${CERTS_DIR}/intermediate-ca/intermediate-ca.csr.pem" \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=MyOrg Intermediate CA"

echo "[2/5] Signing Intermediate CA with Root CA (5 years)..."
openssl x509 -req \
  -in "${CERTS_DIR}/intermediate-ca/intermediate-ca.csr.pem" \
  -CA "${CERTS_DIR}/root-ca/root-ca.cert.pem" \
  -CAkey "${CERTS_DIR}/root-ca/root-ca.key.pem" \
  -passin pass:rootca_password_change_me \
  -CAcreateserial \
  -out "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
  -days 1825 \
  -extensions v3_intermediate_ca \
  -extfile <(cat <<EOF
[ v3_intermediate_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
EOF
)

echo "✅ Intermediate CA created: intermediate-ca/intermediate-ca.cert.pem"

# ─── STEP 3: LEAF CERT - AZURE JENKINS ────────────────────────────────────────
echo ""
echo "[3/5] Generating Azure Jenkins leaf certificate..."
openssl genrsa \
  -out "${CERTS_DIR}/leaf/jenkins-az.key.pem" 2048

openssl req -new \
  -key "${CERTS_DIR}/leaf/jenkins-az.key.pem" \
  -out "${CERTS_DIR}/leaf/jenkins-az.csr.pem" \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=${AZURE_JENKINS_DNS}"

openssl x509 -req \
  -in "${CERTS_DIR}/leaf/jenkins-az.csr.pem" \
  -CA "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
  -CAkey "${CERTS_DIR}/intermediate-ca/intermediate-ca.key.pem" \
  -passin pass:intermediateca_password_change_me \
  -CAcreateserial \
  -out "${CERTS_DIR}/leaf/jenkins-az.cert.pem" \
  -days 365 \
  -extensions v3_leaf \
  -extfile <(cat <<EOF
[ v3_leaf ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints       = critical, CA:false
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = @alt_names_az

[ alt_names_az ]
DNS.1 = ${AZURE_JENKINS_DNS}
DNS.2 = jenkins-az
DNS.3 = localhost
EOF
)

echo "✅ Azure Jenkins leaf cert: leaf/jenkins-az.cert.pem"

# ─── STEP 4: LEAF CERT - GCP JENKINS ──────────────────────────────────────────
echo ""
echo "[4/5] Generating GCP Jenkins leaf certificate..."
openssl genrsa \
  -out "${CERTS_DIR}/leaf/jenkins-gcp.key.pem" 2048

openssl req -new \
  -key "${CERTS_DIR}/leaf/jenkins-gcp.key.pem" \
  -out "${CERTS_DIR}/leaf/jenkins-gcp.csr.pem" \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=${GCP_JENKINS_DNS}"

openssl x509 -req \
  -in "${CERTS_DIR}/leaf/jenkins-gcp.csr.pem" \
  -CA "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
  -CAkey "${CERTS_DIR}/intermediate-ca/intermediate-ca.key.pem" \
  -passin pass:intermediateca_password_change_me \
  -CAcreateserial \
  -out "${CERTS_DIR}/leaf/jenkins-gcp.cert.pem" \
  -days 365 \
  -extensions v3_leaf \
  -extfile <(cat <<EOF
[ v3_leaf ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints       = critical, CA:false
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = @alt_names_gcp

[ alt_names_gcp ]
DNS.1 = ${GCP_JENKINS_DNS}
DNS.2 = jenkins-gcp
DNS.3 = localhost
EOF
)

echo "✅ GCP Jenkins leaf cert: leaf/jenkins-gcp.cert.pem"

# ─── STEP 5: BUILD CERTIFICATE CHAINS ─────────────────────────────────────────
echo ""
echo "[5/5] Building full certificate chains..."

# Full chain = leaf + intermediate + root
cat "${CERTS_DIR}/leaf/jenkins-az.cert.pem" \
    "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
    "${CERTS_DIR}/root-ca/root-ca.cert.pem" \
    > "${CERTS_DIR}/leaf/jenkins-az.chain.pem"

cat "${CERTS_DIR}/leaf/jenkins-gcp.cert.pem" \
    "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
    "${CERTS_DIR}/root-ca/root-ca.cert.pem" \
    > "${CERTS_DIR}/leaf/jenkins-gcp.chain.pem"

# CA bundle (intermediate + root) for trust store
cat "${CERTS_DIR}/intermediate-ca/intermediate-ca.cert.pem" \
    "${CERTS_DIR}/root-ca/root-ca.cert.pem" \
    > "${CERTS_DIR}/ca-bundle.pem"

# PKCS12 bundles for Azure Key Vault import
openssl pkcs12 -export \
  -in "${CERTS_DIR}/leaf/jenkins-az.chain.pem" \
  -inkey "${CERTS_DIR}/leaf/jenkins-az.key.pem" \
  -out "${CERTS_DIR}/leaf/jenkins-az.pfx" \
  -passout pass:pfx_password_change_me \
  -name "jenkins-az"

openssl pkcs12 -export \
  -in "${CERTS_DIR}/leaf/jenkins-gcp.chain.pem" \
  -inkey "${CERTS_DIR}/leaf/jenkins-gcp.key.pem" \
  -out "${CERTS_DIR}/leaf/jenkins-gcp.pfx" \
  -passout pass:pfx_password_change_me \
  -name "jenkins-gcp"

echo ""
echo "================================================"
echo " Certificate Chain Summary"
echo "================================================"
echo ""
echo "Root CA:          certs/root-ca/root-ca.cert.pem"
echo "Intermediate CA:  certs/intermediate-ca/intermediate-ca.cert.pem"
echo "Azure leaf cert:  certs/leaf/jenkins-az.cert.pem"
echo "GCP leaf cert:    certs/leaf/jenkins-gcp.cert.pem"
echo "Azure chain:      certs/leaf/jenkins-az.chain.pem"
echo "GCP chain:        certs/leaf/jenkins-gcp.chain.pem"
echo "CA bundle:        certs/ca-bundle.pem"
echo "Azure PFX:        certs/leaf/jenkins-az.pfx"
echo "GCP PFX:          certs/leaf/jenkins-gcp.pfx"
echo ""
echo "NEXT STEPS:"
echo "  1. Run: terraform apply (azure/certs-keyvault)"
echo "  2. Run: terraform apply (gcp/certs-secretmanager)"
echo "  3. Distribute root-ca.cert.pem to all VPN client laptops"
echo "  4. Install certs on Jenkins VMs via startup script"
echo ""
echo "⚠️  IMPORTANT: Change all passwords before production use!"
echo "⚠️  Keep root-ca.key.pem OFFLINE and secure!"
