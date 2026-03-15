output "jenkins_internal_ip" {
  value = google_compute_instance.jenkins_vm.network_interface[0].network_ip
}

output "jenkins_vm_name" {
  value = google_compute_instance.jenkins_vm.name
}

output "jenkins_service_account_email" {
  value = google_service_account.jenkins_sa.email
}

output "jenkins_dns_record" {
  value = google_dns_record_set.jenkins_dns.name
}
