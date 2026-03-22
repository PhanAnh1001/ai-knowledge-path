# =============================================================================
# Oracle Cloud Infrastructure — Input Variables
# Sao chép terraform.tfvars.example → terraform.tfvars rồi điền giá trị thật
# =============================================================================

# ── OCI Credentials ──────────────────────────────────────────────────────────
variable "tenancy_ocid" {
  description = "OCID của tenancy. Lấy từ: OCI Console → Profile → Tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID của user API. Lấy từ: OCI Console → Profile → User settings"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint của API key. Lấy từ: User settings → API Keys"
  type        = string
}

variable "private_key_path" {
  description = "Đường dẫn file private key OCI API (PEM). Ví dụ: ~/.oci/oci_api_key.pem"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI region. Ví dụ: ap-singapore-1, ap-tokyo-1, us-ashburn-1"
  type        = string
  default     = "ap-singapore-1"
}

variable "compartment_ocid" {
  description = "OCID của compartment (thường là root compartment = tenancy_ocid)"
  type        = string
}

# ── SSH Access ────────────────────────────────────────────────────────────────
variable "ssh_public_key" {
  description = "Nội dung SSH public key để SSH vào VM. Ví dụ: ssh-rsa AAAA..."
  type        = string
}

# ── Instance ──────────────────────────────────────────────────────────────────
variable "instance_ocpus" {
  description = "Số OCPU cho ARM A1 instance (Always Free tối đa 4)"
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "RAM GB cho ARM A1 instance (Always Free tối đa 24)"
  type        = number
  default     = 24
}

variable "boot_volume_gb" {
  description = "Dung lượng boot volume (GB). Always Free tổng cộng 200GB"
  type        = number
  default     = 100
}

# ── Site Address (cho Caddy SSL) ──────────────────────────────────────────────
variable "site_address" {
  description = <<-EOT
    Địa chỉ website cho Caddy (tự động cấp SSL Let's Encrypt).
    - Chưa có domain: để trống "", sau khi VM tạo xong điền IP vào .env theo dạng X.X.X.X.sslip.io
    - Có domain: điền domain thật, ví dụ "awb.example.com"
  EOT
  type    = string
  default = ""
}
