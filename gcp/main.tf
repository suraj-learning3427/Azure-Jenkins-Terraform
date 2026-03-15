terraform {
  required_version = ">= 1.0"
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

# ─── NETWORKING ───────────────────────────────────────────────────────────────
module "networking" {
  source = "./networking"

  project_id           = var.project_id
  region               = var.region
  name_prefix          = var.name_prefix
  jenkins_subnet_cidr  = var.jenkins_subnet_cidr
  vpn_subnet_cidr      = var.vpn_subnet_cidr
  firezone_client_cidr = var.firezone_client_cidr
  dns_domain           = var.dns_domain
}

# ─── FIREZONE GATEWAY ─────────────────────────────────────────────────────────
module "firezone_gateway" {
  source = "./firezone-gateway"

  project_id      = var.project_id
  region          = var.region
  name_prefix     = var.name_prefix
  subnet_vpn_name = module.networking.subnet_vpn_name
  machine_type    = var.firezone_machine_type
  ssh_public_key  = var.ssh_public_key
  firezone_id     = var.firezone_id
  firezone_token  = var.firezone_token
  labels          = var.labels

  depends_on = [module.networking]
}

# ─── JENKINS VM ───────────────────────────────────────────────────────────────
module "jenkins_vm" {
  source = "./jenkins-vm"

  project_id          = var.project_id
  region              = var.region
  name_prefix         = var.name_prefix
  subnet_jenkins_name = module.networking.subnet_jenkins_name
  machine_type        = var.jenkins_machine_type
  ssh_public_key      = var.ssh_public_key
  data_disk_size_gb   = var.jenkins_data_disk_size_gb
  jenkins_port        = var.jenkins_port
  dns_zone_name       = module.networking.dns_zone_name
  dns_domain          = var.dns_domain
  labels              = var.labels

  depends_on = [module.networking]
}
