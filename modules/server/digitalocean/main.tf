variable "name" {}
variable "ssh_key" {}
variable "domains" {}
variable "size" {
  default = "s-1vcpu-2gb"
}
variable "label" {
  default = "default"
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# SSH key used for auth on all nodes
resource "digitalocean_ssh_key" "default" {
  name       = "Server SSH key"
  public_key = var.ssh_key
}

resource "digitalocean_droplet" "nixos" {
  name = var.name

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [image, ssh_keys]
  }

  size = var.size
  image = "ubuntu-24-04-x64"
  ssh_keys           = [digitalocean_ssh_key.default.fingerprint]
  region             = "ams3"
}

output "node" {
  value = {
    provider = "digitalocean"
    name     = var.name
    ip       = digitalocean_droplet.nixos.ipv4_address
    ssh_key  = var.ssh_key
    domains   = var.domains
    label    = var.label
  }
}

###########
# EXAMPLE #
###########
# module "vps1" {
#   source        = "./modules/server/digitalocean"
#   name          = "vps1"
#   label         = "seed"
#   ssh_key       = var.ssh_pub
#   size          = "s-2vcpu-4gb"
#   domains        = {}
# }