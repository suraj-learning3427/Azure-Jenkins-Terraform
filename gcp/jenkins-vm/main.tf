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

# ─── SERVICE ACCOUNT ──────────────────────────────────────────────────────────
resource "google_service_account" "jenkins_sa" {
  account_id   = "${var.name_prefix}jenkins-vm-sa"
  display_name = "Jenkins VM Service Account"
  project      = var.project_id
}

# Allow Jenkins SA to read secrets from Secret Manager
resource "google_project_iam_member" "jenkins_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# ─── PERSISTENT DISK FOR JENKINS DATA ─────────────────────────────────────────
resource "google_compute_disk" "jenkins_data" {
  name    = "${var.name_prefix}jenkins-data"
  type    = "pd-ssd"
  zone    = "${var.region}-a"
  size    = var.data_disk_size_gb
  project = var.project_id

  labels = var.labels
}

# ─── JENKINS VM (PRIVATE — NO PUBLIC IP) ──────────────────────────────────────
resource "google_compute_instance" "jenkins_vm" {
  name         = "${var.name_prefix}jenkins-server"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = ["jenkins-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-ssd"
    }
  }

  # Attach persistent data disk
  attached_disk {
    source      = google_compute_disk.jenkins_data.id
    device_name = "jenkins-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.subnet_jenkins_name
    # No access_config = no public IP
  }

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  metadata_startup_script = templatefile("${path.module}/templates/jenkins-startup.sh", {
    data_disk_device = "/dev/disk/by-id/google-jenkins-data"
    mount_point      = "/jenkins"
    jenkins_port     = var.jenkins_port
  })

  labels = var.labels
}

# ─── DNS A RECORD ─────────────────────────────────────────────────────────────
resource "google_dns_record_set" "jenkins_dns" {
  name         = "jenkins-gcp.${var.dns_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  project      = var.project_id

  rrdatas = [google_compute_instance.jenkins_vm.network_interface[0].network_ip]
}
