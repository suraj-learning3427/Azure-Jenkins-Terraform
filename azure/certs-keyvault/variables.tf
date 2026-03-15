variable "resource_group_name" {
  type    = string
  default = "azure-jenkins-core-infrastructure-rg"
}

variable "pfx_password" {
  type      = string
  sensitive = true
  default   = "pfx_password_change_me"
}

variable "jenkins_vm_identity_principal_id" {
  type        = string
  description = "Principal ID of the Jenkins VM managed identity"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = { Environment = "production", Project = "jenkins", ManagedBy = "terraform" }
}
