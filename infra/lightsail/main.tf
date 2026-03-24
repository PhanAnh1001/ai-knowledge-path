# =============================================================================
# AWS Lightsail — AI Wisdom Battle
# Tạo instance Ubuntu 24.04 tại Singapore, IPv6-only, $7/tháng
#
# Yêu cầu:
#   terraform >= 1.5
#   provider hashicorp/aws ~> 5.0
#
# Sử dụng:
#   terraform init
#   terraform plan
#   terraform apply
#   terraform output ipv6_address
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── SSH Key Pair ──────────────────────────────────────────────────────────────
resource "aws_lightsail_key_pair" "awb_key" {
  name       = "awb-deploy-key"
  public_key = var.ssh_public_key
}

# ── Lightsail Instance ────────────────────────────────────────────────────────
resource "aws_lightsail_instance" "awb_prod" {
  name              = "awb-prod"
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = var.bundle_id
  key_pair_name     = aws_lightsail_key_pair.awb_key.name
  ip_address_type   = "ipv6"

  # Bootstrap: cài Docker, clone repo, cấu hình firewall
  user_data = file("${path.module}/../../scripts/lightsail-init.sh")

  tags = {
    Project     = "ai-wisdom-battle"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ── Firewall Ports ────────────────────────────────────────────────────────────
# Lightsail có firewall riêng — cần mở thêm ngoài security group mặc định
resource "aws_lightsail_instance_public_ports" "awb_ports" {
  instance_name = aws_lightsail_instance.awb_prod.name

  # SSH — quản trị
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }

  # HTTP — Caddy redirect sang HTTPS
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }

  # HTTPS TCP — API và frontend
  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }

  # HTTPS UDP — HTTP/3 (QUIC) qua Caddy
  port_info {
    protocol  = "udp"
    from_port = 443
    to_port   = 443
  }
}
