variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region for deployment"
}

variable "name_prefix" {
  type        = string
  default     = "jenkins-"
  description = "Prefix for all resource names"
}

variable "jenkins_subnet_cidr" {
  type        = string
  default     = "10.10.0.0/24"
  description = "CIDR for Jenkins private subnet"
}

variable "vpn_subnet_cidr" {
  type        = string
  default     = "10.10.1.0/24"
  description = "CIDR for Firezone/VPN subnet"
}

variable "firezone_client_cidr" {
  type        = string
  default     = "100.64.0.0/10"
  description = "CIDR range assigned to Firezone VPN clients"
}

variable "dns_domain" {
  type        = string
  default     = "internal.company"
  description = "Private DNS domain"
}

variable "firezone_machine_type" {
  type        = string
  default     = "e2-medium"
  description = "GCP machine type for Firezone gateway"
}

variable "jenkins_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "GCP machine type for Jenkins VM"
}

variable "jenkins_data_disk_size_gb" {
  type        = number
  default     = 50
  description = "Size of Jenkins data disk in GB"
}

variable "jenkins_port" {
  type        = number
  default     = 8080
  description = "Jenkins HTTP port"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
}

variable "firezone_id" {
  type        = string
  sensitive   = true
  description = "Firezone gateway ID"
}

variable "firezone_token" {
  type        = string
  sensitive   = true
  description = "Firezone authentication token"
}

variable "labels" {
  type = map(string)
  default = {
    environment = "production"
    project     = "jenkins"
    managed_by  = "terraform"
  }
}
