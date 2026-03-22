# =============================================================================
# Outputs — hiển thị sau khi terraform apply thành công
# =============================================================================

output "public_ip" {
  description = "Public IP của Oracle Cloud VM"
  value       = oci_core_instance.awb_server.public_ip
}

output "ssh_command" {
  description = "Lệnh SSH vào VM"
  value       = "ssh -i <đường-dẫn-private-key> ubuntu@${oci_core_instance.awb_server.public_ip}"
}

output "site_address" {
  description = "Địa chỉ website (dùng sslip.io nếu chưa có domain)"
  value       = "${oci_core_instance.awb_server.public_ip}.sslip.io"
}

output "instance_id" {
  description = "OCID của instance"
  value       = oci_core_instance.awb_server.id
}
