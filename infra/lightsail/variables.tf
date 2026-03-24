variable "aws_region" {
  description = "AWS region cho Lightsail instance (ap-southeast-1 = Singapore)"
  type        = string
  default     = "ap-southeast-1"
}

variable "bundle_id" {
  description = "Lightsail bundle ID — IPv6-only instance phải dùng bundle _ipv6_. small_ipv6_3_0 = 2vCPU·2GB·$10/tháng"
  type        = string
  default     = "small_ipv6_3_0"

  validation {
    condition     = contains(["nano_ipv6_3_0", "micro_ipv6_3_0", "small_ipv6_3_0", "medium_ipv6_3_0"], var.bundle_id)
    error_message = "IPv6-only instance phải dùng bundle _ipv6_: nano_ipv6_3_0, micro_ipv6_3_0, small_ipv6_3_0, medium_ipv6_3_0"
  }
}

variable "ssh_public_key" {
  description = "Nội dung SSH public key để SSH vào instance (ví dụ: ssh-ed25519 AAAA...)"
  type        = string
  sensitive   = true
}
