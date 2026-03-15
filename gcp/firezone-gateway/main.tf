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
resource "google_service_account" "firezone_sa" {
  account_id   = "${var.name_prefix}firezone-gw-sa"
  display_name = "Firezone Gateway Service Account"
  project      = var.project_id
}

# ─── STATIC EXTERNAL IP ───────────────────────────────────────────────────────
resource "google_compute_address" "firezone_ip" {
  name    = "${var.name_prefix}firezone-gateway-ip"
  region  = var.region
  project = var.project_id
}

# ─── FIREZONE GATEWAY VM ──────────────────────────────────────────────────────
resource "google_compute_instance" "firezone_gateway" {
  name         = "${var.name_prefix}firezone-gateway"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = ["firezone-gateway"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.subnet_vpn_name
    access_config {
      nat_ip = google_compute_address.firezone_ip.address
    }
  }

  service_account {
    email  = google_service_account.firezone_sa.email
    scopes = ["cloud-platform"]
  }

  # Enable IP forwarding for VPN routing
  can_ip_forward = true

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  metadata_startup_script = templatefile("${path.module}/templates/firezone-startup.sh", {
    firezone_token = var.firezone_token
    firezone_id    = var.firezone_id
    log_level      = var.log_level
  })

  labels = var.labels
}
