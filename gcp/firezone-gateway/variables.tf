variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  type        = string
  default     = "jenkins-"
}

variable "subnet_vpn_name" {
  type        = string
  description = "Name of the VPN subnet (self_link or name)"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
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

variable "log_level" {
  type    = string
  default = "info"
}

variable "labels" {
  type    = map(string)
  default = {}
}
