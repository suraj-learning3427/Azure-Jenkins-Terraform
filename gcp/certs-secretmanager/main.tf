terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── ROOT CA CERT ─────────────────────────────────────────────────────────────
resource "google_secret_manager_secret" "root_ca_cert" {
  secret_id = "jenkins-root-ca-cert"
  project   = var.project_id
  labels    = { cert-type = "root-ca", env = "production" }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "root_ca_cert" {
  secret      = google_secret_manager_secret.root_ca_cert.id
  secret_data = file("${path.root}/../../certs/root-ca/root-ca.cert.pem")
}

# ─── INTERMEDIATE CA CERT ─────────────────────────────────────────────────────
resource "google_secret_manager_secret" "intermediate_ca_cert" {
  secret_id = "jenkins-intermediate-ca-cert"
  project   = var.project_id
  labels    = { cert-type = "intermediate-ca", env = "production" }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "intermediate_ca_cert" {
  secret      = google_secret_manager_secret.intermediate_ca_cert.id
  secret_data = file("${path.root}/../../certs/intermediate-ca/intermediate-ca.cert.pem")
}

# ─── GCP JENKINS LEAF CERT ────────────────────────────────────────────────────
resource "google_secret_manager_secret" "jenkins_gcp_cert" {
  secret_id = "jenkins-gcp-leaf-cert"
  project   = var.project_id
  labels    = { cert-type = "leaf", cloud = "gcp", env = "production" }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jenkins_gcp_cert" {
  secret      = google_secret_manager_secret.jenkins_gcp_cert.id
  secret_data = file("${path.root}/../../certs/leaf/jenkins-gcp.cert.pem")
}

# ─── GCP JENKINS PRIVATE KEY ──────────────────────────────────────────────────
resource "google_secret_manager_secret" "jenkins_gcp_key" {
  secret_id = "jenkins-gcp-leaf-key"
  project   = var.project_id
  labels    = { cert-type = "leaf-key", cloud = "gcp", env = "production" }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jenkins_gcp_key" {
  secret      = google_secret_manager_secret.jenkins_gcp_key.id
  secret_data = file("${path.root}/../../certs/leaf/jenkins-gcp.key.pem")
}

# ─── GCP JENKINS FULL CHAIN ───────────────────────────────────────────────────
resource "google_secret_manager_secret" "jenkins_gcp_chain" {
  secret_id = "jenkins-gcp-chain"
  project   = var.project_id
  labels    = { cert-type = "leaf-chain", cloud = "gcp", env = "production" }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jenkins_gcp_chain" {
  secret      = google_secret_manager_secret.jenkins_gcp_chain.id
  secret_data = file("${path.root}/../../certs/leaf/jenkins-gcp.chain.pem")
}

# ─── GRANT JENKINS VM SERVICE ACCOUNT ACCESS ──────────────────────────────────
resource "google_secret_manager_secret_iam_member" "jenkins_vm_cert_access" {
  for_each = toset([
    google_secret_manager_secret.jenkins_gcp_cert.secret_id,
    google_secret_manager_secret.jenkins_gcp_key.secret_id,
    google_secret_manager_secret.jenkins_gcp_chain.secret_id,
    google_secret_manager_secret.root_ca_cert.secret_id,
  ])
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.jenkins_vm_service_account}"
}
