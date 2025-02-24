variable "ssh_pub" {}
variable "cloudflare_id" {}

# module "vps1" {
#   source        = "./modules/server/digitalocean"
#   name          = "vps1"
#   label         = "seed"
#   ssh_key       = var.ssh_pub
#   size          = "s-2vcpu-4gb"
#   domains        = {
#     "friikod" = "friikod.se",
#     "ladugardlive" = "ladugardlive.se",
#     "uno-api" = "unoapi.friikod.se",
#     "calc-api" = "calc.friikod.se",
#     "meili" = "meili.friikod.se",
#     "enshrouded" = "enshrouded.friikod.se",
#     "auth-server" = "auth-server.friikod.se"
#   }
# }

module "hetzvps" {
  source = "./modules/server/hetzner"
  name = "hetzvps"
  ssh_key = var.ssh_pub
  image = "ubuntu-22.04"
  server_type = "cpx31"
  label = "seed"

  domains        = {
    "friikod" = "friikod.se",
    "ladugardlive" = "ladugardlive.se",
    "calc-api" = "calc.friikod.se",
    "meili" = "meili.friikod.se",
    "enshrouded" = "enshrouded.friikod.se",
    "auth-server" = "auth-server.friikod.se"
  }
}

module "dns_friikod_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "friikod.se"
  subdomains = ["www", "calc", "meili", "enshrouded", "auth-server"]
  ip = module.hetzvps.node.ip
  # ip6 = module.server.nodes.ip6
}

module "dns_ladugard_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "ladugardlive.se"
  subdomains = ["www"]
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
