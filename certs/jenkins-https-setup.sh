#!/bin/bash
# Jenkins HTTPS Setup Script
# Pulls certs from Azure Key Vault (Azure) or GCP Secret Manager (GCP)
# Run on Jenkins VM after cert generation and Terraform apply

set -e
CLOUD="${CLOUD:-azure}"   # set to "gcp" on GCP VMs
KV_NAME="${KV_NAME:-}"    # Azure Key Vault name
GCP_PROJECT="${GCP_PROJECT:-}"
JENKINS_HOME="${JENKINS_HOME:-/jenkins/jenkins_home}"
CERT_DIR="/etc/jenkins/certs"

mkdir -p "$CERT_DIR"

echo "=== Installing Jenkins HTTPS Certificates (${CLOUD}) ==="

if [ "$CLOUD" = "azure" ]; then
  # ── Pull from Azure Key Vault using managed identity ──────────────────────
  echo "Fetching certs from Azure Key Vault: $KV_NAME"
  TOKEN=$(curl -s -H "Metadata:true" \
    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

  fetch_secret() {
    local name=$1 outfile=$2
    curl -s -H "Authorization: Bearer $TOKEN" \
      "https://${KV_NAME}.vault.azure.net/secrets/${name}?api-version=7.3" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])" > "$outfile"
    echo "  ✅ $name → $outfile"
  }

  fetch_secret "jenkins-az-chain"  "$CERT_DIR/jenkins.chain.pem"
  fetch_secret "jenkins-az-key"    "$CERT_DIR/jenkins.key.pem"
  fetch_secret "root-ca-cert"      "$CERT_DIR/root-ca.pem"

elif [ "$CLOUD" = "gcp" ]; then
  # ── Pull from GCP Secret Manager using metadata server ────────────────────
  echo "Fetching certs from GCP Secret Manager: $GCP_PROJECT"
  TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

  fetch_secret() {
    local name=$1 outfile=$2
    curl -s -H "Authorization: Bearer $TOKEN" \
      "https://secretmanager.googleapis.com/v1/projects/${GCP_PROJECT}/secrets/${name}/versions/latest:access" \
      | python3 -c "import sys,json,base64; print(base64.b64decode(json.load(sys.stdin)['payload']['data']).decode())" > "$outfile"
    echo "  ✅ $name → $outfile"
  }

  fetch_secret "jenkins-gcp-chain"    "$CERT_DIR/jenkins.chain.pem"
  fetch_secret "jenkins-gcp-leaf-key" "$CERT_DIR/jenkins.key.pem"
  fetch_secret "jenkins-root-ca-cert" "$CERT_DIR/root-ca.pem"
fi

chmod 600 "$CERT_DIR/jenkins.key.pem"
chmod 644 "$CERT_DIR/jenkins.chain.pem"
chmod 644 "$CERT_DIR/root-ca.pem"

# ── Convert PEM chain + key to PKCS12 keystore for Jenkins ────────────────────
echo "Converting to PKCS12 keystore for Jenkins..."
openssl pkcs12 -export \
  -in  "$CERT_DIR/jenkins.chain.pem" \
  -inkey "$CERT_DIR/jenkins.key.pem" \
  -out "$CERT_DIR/jenkins.p12" \
  -passout pass:changeit \
  -name jenkins

# ── Configure Jenkins to use HTTPS ────────────────────────────────────────────
echo "Configuring Jenkins HTTPS..."
cat > /etc/systemd/system/jenkins.service.d/https.conf <<EOF
[Service]
Environment="JENKINS_HTTPS_PORT=8443"
Environment="JENKINS_HTTPS_KEYSTORE=${CERT_DIR}/jenkins.p12"
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"
Environment="JENKINS_PORT=-1"
EOF

# ── Install Root CA in system trust store (so Jenkins trusts Entra ID) ────────
echo "Installing Root CA in system trust store..."
cp "$CERT_DIR/root-ca.pem" /usr/local/share/ca-certificates/myorg-root-ca.crt
update-ca-certificates

systemctl daemon-reload
systemctl restart jenkins

echo ""
echo "✅ Jenkins HTTPS configured on port 8443"
echo "✅ Root CA trusted by system"
echo "   Access: https://$(hostname):8443"
