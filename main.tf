variable "ssh_pub" {}
variable "cloudflare_id" {}


module "vps1" {
  source        = "./modules/server"
  name          = "vps1"
  label         = "seed"
  ssh_key       = var.ssh_pub
  size          = "s-1vcpu-2gb"
  domains        = {
    "friikod" = "friikod.se",
    "ladugardlive" = "ladugardlive.se",
    "uno-api" = "unoapi.friikod.se",
    "calc-api" = "calc.friikod.se",
    "weland-wp" = "weland.friikod.se"
  }
}

module "dns_friikod_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "friikod.se"
  subdomains = ["www", "unoapi", "calc", "weland"]
  ip = module.vps1.node.ip
  # ip6 = module.server.nodes.ip6
}

module "dns_ladugard_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "ladugardlive.se"
  subdomains = ["www"]
  ip = module.vps1.node.ip
  # ip6 = module.server.nodes.ip6
}

# Add DNS servers to opentofu output.
output "ns" {
  value = {
    "${module.vps1.node.domains.friikod}" = module.dns_friikod_se.ns,
    "${module.vps1.node.domains.ladugardlive}" = module.dns_ladugard_se.ns
  }
}

# Add all node information to output for `terraflake`.
output "terraflake" {
  # value = [module.vps1.node, module.node2.node]
  value = module.vps1.node
}
