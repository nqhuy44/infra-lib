output "ids" {
  description = "List of Elastic IP allocation IDs"
  value       = aws_eip.this[*].id
}

output "public_ips" {
  description = "List of Elastic IP public IP addresses"
  value       = aws_eip.this[*].public_ip
}

output "private_ips" {
  description = "List of Elastic IP private IP addresses (if associated with network interfaces)"
  value       = aws_eip.this[*].private_ip
}

output "public_dns" {
  description = "List of Elastic IP public DNS names"
  value       = aws_eip.this[*].public_dns
}

output "associations" {
  description = "List of Elastic IP association IDs"
  value       = aws_eip.this[*].association_id
}