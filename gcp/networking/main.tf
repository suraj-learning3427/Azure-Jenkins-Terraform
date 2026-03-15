terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ─── VPC ──────────────────────────────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# ─── SUBNETS ──────────────────────────────────────────────────────────────────
resource "google_compute_subnetwork" "subnet_jenkins" {
  name          = "${var.name_prefix}subnet-jenkins"
  ip_cidr_range = var.jenkins_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "subnet_vpn" {
  name          = "${var.name_prefix}subnet-vpn"
  ip_cidr_range = var.vpn_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# ─── FIREWALL RULES ───────────────────────────────────────────────────────────
# Allow SSH via IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.name_prefix}allow-iap-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP range
  target_tags   = ["jenkins-server", "firezone-gateway"]
}

# Allow Jenkins access from VPN subnet only
resource "google_compute_firewall" "allow_jenkins_from_vpn" {
  name    = "${var.name_prefix}allow-jenkins-vpn"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_ranges = [var.vpn_subnet_cidr, var.firezone_client_cidr]
  target_tags   = ["jenkins-server"]
}

# Allow WireGuard (Firezone) inbound
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.name_prefix}allow-wireguard"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["firezone-gateway"]
}

# Allow health check from load balancer
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.name_prefix}allow-health-check"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP LB health check ranges
  target_tags   = ["firezone-gateway"]
}

# Allow internal VPC traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.jenkins_subnet_cidr, var.vpn_subnet_cidr]
}

# Allow DNS queries from Firezone VPN clients through the gateway
# Firezone gateway receives DNS on port 53 and forwards to GCP resolver (169.254.169.254)
resource "google_compute_firewall" "allow_dns_from_vpn" {
  name    = "${var.name_prefix}allow-dns-vpn-clients"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "udp"
    ports    = ["53"]
  }
  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  source_ranges = [var.firezone_client_cidr]
  target_tags   = ["firezone-gateway"]
}

# ─── CLOUD ROUTER + NAT (for private Jenkins VM outbound) ─────────────────────
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet_jenkins.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# ─── PRIVATE DNS ZONE ─────────────────────────────────────────────────────────
resource "google_dns_managed_zone" "internal" {
  name        = "${var.name_prefix}internal-dns"
  dns_name    = "${var.dns_domain}."
  description = "Private DNS zone for internal services"
  project     = var.project_id

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}
