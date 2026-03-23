output "ipv6_address" {
  description = "IPv6 address của Lightsail instance — dùng để cấu hình Cloudflare AAAA record"
  value       = aws_lightsail_instance.awb_prod.ipv6_addresses[0]
}

output "instance_name" {
  description = "Tên Lightsail instance"
  value       = aws_lightsail_instance.awb_prod.name
}

output "ssh_command" {
  description = "Lệnh SSH để kết nối vào instance"
  value       = "ssh -i ~/.ssh/awb-lightsail ubuntu@${aws_lightsail_instance.awb_prod.ipv6_addresses[0]}"
}

output "instance_arn" {
  description = "ARN của Lightsail instance"
  value       = aws_lightsail_instance.awb_prod.arn
}
