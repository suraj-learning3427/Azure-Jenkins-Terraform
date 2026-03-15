output "firezone_gateway_external_ip" {
  value = google_compute_address.firezone_ip.address
}

output "firezone_gateway_internal_ip" {
  value = google_compute_instance.firezone_gateway.network_interface[0].network_ip
}

output "firezone_gateway_name" {
  value = google_compute_instance.firezone_gateway.name
}

output "firezone_service_account_email" {
  value = google_service_account.firezone_sa.email
}
