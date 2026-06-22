variable "cloudflare_id" {}
variable "cloudflare_token" {}
variable "ssh_pub" {}
variable "storagebox_backups_password" {}

module "friikod" {
  source                      = "../infrastructure/friikod"
  cloudflare_id               = var.cloudflare_id
  cloudflare_token            = var.cloudflare_token
  ssh_pub                     = var.ssh_pub
  storagebox_backups_password = var.storagebox_backups_password
}

# Add all node information to output for `terraflake`.
output "terraflake" {
  value = [
    module.friikod.nodes.friikod,
  ]
}
output "cloudflare_tunnel_token_friikod" {
  value     = module.friikod.tunnel_token
  sensitive = true
}
