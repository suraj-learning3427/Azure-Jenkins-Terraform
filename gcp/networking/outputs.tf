output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_jenkins_name" {
  value = google_compute_subnetwork.subnet_jenkins.name
}

output "subnet_vpn_name" {
  value = google_compute_subnetwork.subnet_vpn.name
}

output "dns_zone_name" {
  value = google_dns_managed_zone.internal.name
}

output "dns_zone_dns_name" {
  value = google_dns_managed_zone.internal.dns_name
}
