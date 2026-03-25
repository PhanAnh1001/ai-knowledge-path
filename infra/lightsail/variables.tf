variable "aws_region" {
  description = "AWS region cho Lightsail instance (ap-southeast-1 = Singapore)"
  type        = string
  default     = "ap-southeast-1"
}

variable "bundle_id" {
  description = "Lightsail bundle ID. small_3_0 = 2vCPU·2GB·$10/tháng (IPv4)"
  type        = string
  default     = "small_3_0"

  validation {
    condition     = contains(["nano_3_0", "micro_3_0", "small_3_0", "medium_3_0"], var.bundle_id)
    error_message = "bundle_id phải là một trong: nano_3_0, micro_3_0, small_3_0, medium_3_0"
  }
}

variable "ssh_public_key" {
  description = "Nội dung SSH public key để SSH vào instance (ví dụ: ssh-ed25519 AAAA...)"
  type        = string
  sensitive   = true
}
