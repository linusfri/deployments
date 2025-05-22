variable "ssh_pub" {}
variable "cloudflare_id" {}

module "hetzvps" {
  source = "./modules/server/hetzner/vps"
  name = "hetzvps"
  ssh_key = var.ssh_pub
  image = "ubuntu-22.04"
  server_type = "cpx31"
  label = "seed"

  domains        = {
    "friikod" = "friikod.se",
    "ladugardlive" = "ladugardlive.se",
    "calc-api" = "calc.friikod.se"
    "auth-server" = "auth-server.friikod.se"
    "strapi" = "strapi.friikod.se"
    "next" = "next.friikod.se"
  }
}

module "dns_friikod_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "friikod.se"
  subdomains = {
    "www" = module.hetzvps.node.ip
    "calc" = module.hetzvps.node.ip
    "auth-server" = module.hetzvps.node.ip
    "strapi" = module.hetzvps.node.ip
    "next" = module.hetzvps.node.ip
  }
  ip = module.hetzvps.node.ip
  # ip6 = module.server.nodes.ip6
}

module "dns_ladugard_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "ladugardlive.se"
  subdomains = {
    "www" = module.hetzvps.node.ip
  }
  ip = module.hetzvps.node.ip
  # ip6 = module.server.nodes.ip6
}

# Add DNS servers to opentofu output.
output "ns" {
  value = {
    "${module.hetzvps.node.domains.friikod}" = module.dns_friikod_se.ns,
    "${module.hetzvps.node.domains.ladugardlive}" = module.dns_ladugard_se.ns
  }
}

# Add all node information to output for `terraflake`.
output "terraflake" {
  # value = [module.node1.node, module.node2.node]
  value = [module.hetzvps.node]
}
