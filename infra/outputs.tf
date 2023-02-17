output "dns_ns_records" {
  description = "NS DNS records required for the DNS zone"
  value       = aws_route53_zone.main.name_servers
}
