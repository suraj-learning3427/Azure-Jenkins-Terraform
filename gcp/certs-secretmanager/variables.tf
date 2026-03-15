variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "jenkins_vm_service_account" {
  type        = string
  description = "GCP service account email for Jenkins VM (e.g. jenkins-vm-sa@project.iam.gserviceaccount.com)"
}
