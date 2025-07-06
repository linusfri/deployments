# SSH key used for auth on all nodes
resource "digitalocean_ssh_key" "default" {
  name       = "Server SSH key"
  public_key = var.ssh_pub
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
    name     = digitalocean_droplet.nixos.name
    ip       = digitalocean_droplet.nixos.ipv4_address
    ssh_key  = var.pub
    domains  = var.domains
    label    = "nixos"
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