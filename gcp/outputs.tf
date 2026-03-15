output "firezone_gateway_external_ip" {
  description = "Public IP of the Firezone gateway"
  value       = module.firezone_gateway.firezone_gateway_external_ip
}

output "jenkins_internal_ip" {
  description = "Private IP of the Jenkins VM"
  value       = module.jenkins_vm.jenkins_internal_ip
}

output "jenkins_dns" {
  description = "DNS name for Jenkins (accessible over VPN)"
  value       = "jenkins-gcp.${var.dns_domain}"
}

output "jenkins_service_account" {
  description = "Jenkins VM service account email"
  value       = module.jenkins_vm.jenkins_service_account_email
}
