# =============================================================================
# Oracle Cloud Infrastructure — AI Wisdom Battle
# Tạo toàn bộ hạ tầng: VCN, Subnet, Security List, ARM A1 Instance
#
# Yêu cầu:
#   terraform >= 1.5
#   provider oracle/oci ~> 5.0
#
# Sử dụng:
#   terraform init
#   terraform plan
#   terraform apply
#   terraform output public_ip
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ── Data: Availability Domain đầu tiên ───────────────────────────────────────
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# ── Data: Ubuntu 22.04 Minimal aarch64 (ARM) ─────────────────────────────────
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [".*aarch64.*"]
    regex  = true
  }
}

# ── VCN ──────────────────────────────────────────────────────────────────────
resource "oci_core_vcn" "awb_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "awb-vcn"
  dns_label      = "awbvcn"
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "oci_core_internet_gateway" "awb_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awb_vcn.id
  display_name   = "awb-igw"
  enabled        = true
}

# ── Route Table ───────────────────────────────────────────────────────────────
resource "oci_core_route_table" "awb_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awb_vcn.id
  display_name   = "awb-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.awb_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# ── Security List ─────────────────────────────────────────────────────────────
resource "oci_core_security_list" "awb_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awb_vcn.id
  display_name   = "awb-security-list"

  # Egress: tất cả traffic ra ngoài
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Ingress: SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: HTTP (Caddy redirect sang HTTPS)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress: HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress: ICMP type 3,4 (Path MTU Discovery — khuyến nghị)
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# ── Public Subnet ─────────────────────────────────────────────────────────────
resource "oci_core_subnet" "awb_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.awb_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "awb-public-subnet"
  dns_label         = "awbsubnet"
  route_table_id    = oci_core_route_table.awb_rt.id
  security_list_ids = [oci_core_security_list.awb_sl.id]
}

# ── ARM A1 Instance ───────────────────────────────────────────────────────────
resource "oci_core_instance" "awb_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "awb-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.awb_subnet.id
    display_name     = "awb-vnic"
    assign_public_ip = true
    hostname_label   = "awb-server"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yml"))
  }

  # Giữ instance khi destroy (bảo vệ data)
  # lifecycle {
  #   prevent_destroy = true
  # }
}
