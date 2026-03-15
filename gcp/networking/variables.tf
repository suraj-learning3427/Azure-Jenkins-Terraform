variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
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
  description = "CIDR for VPN/Firezone subnet"
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
