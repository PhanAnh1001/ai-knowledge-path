output "public_ip_address" {
  description = "Public IPv4 address của Lightsail instance — dùng để cấu hình Cloudflare A record"
  value       = aws_lightsail_instance.awb_prod.public_ip_address
}

output "instance_name" {
  description = "Tên Lightsail instance"
  value       = aws_lightsail_instance.awb_prod.name
}

output "ssh_command" {
  description = "Lệnh SSH để kết nối vào instance"
  value       = "ssh -i ~/.ssh/awb-lightsail ubuntu@${aws_lightsail_instance.awb_prod.public_ip_address}"
}

output "instance_arn" {
  description = "ARN của Lightsail instance"
  value       = aws_lightsail_instance.awb_prod.arn
}
