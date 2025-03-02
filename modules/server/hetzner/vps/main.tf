variable "name" {}
variable "ssh_key" {}
variable "domains" {}
variable "server_type" {
  default = "cpx11"
}
variable "image" {
    default = "ubuntu-22.04"
}
variable "label" {
  default = "default"
}

terraform {
  required_providers {
    hcloud = {
      source  = "opentofu/hcloud"
      version = "~> 1.49.1"
    }
  }
}

resource "hcloud_ssh_key" "main" {
  name       = "main_ssh"
  public_key = var.ssh_key
}

resource "hcloud_server" "nixos" {
  name        = var.name
  image       = var.image
  server_type = var.server_type
  datacenter  = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
  labels = {
    "label" : var.label
  }
}

output "node" {
  value = {
    provider = "hetznercloud"
    name     = var.name
    ip       = hcloud_server.nixos.ipv4_address
    ssh_key  = var.ssh_key
    domains  = var.domains
    label    = var.label
  }
}
