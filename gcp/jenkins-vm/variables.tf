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

variable "subnet_jenkins_name" {
  type        = string
  description = "Self-link or name of the Jenkins private subnet"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
}

variable "data_disk_size_gb" {
  type    = number
  default = 50
}

variable "jenkins_port" {
  type    = number
  default = 8080
}

variable "dns_zone_name" {
  type        = string
  description = "Name of the Cloud DNS managed zone"
}

variable "dns_domain" {
  type        = string
  default     = "internal.company"
  description = "Private DNS domain (without trailing dot)"
}

variable "labels" {
  type    = map(string)
  default = {}
}
