variable "ssh_pub" {}
variable "cloudflare_id" {}


module "vps1" {
  source        = "./modules/server"
  name          = "vps1"
  label         = "seed"
  ssh_key       = var.ssh_pub
  domain        = "mjaumjau.se"
}

module "dns_mjaumjau_se" {
  source     = "./modules/dns"
  account_id = var.cloudflare_id
  domain     = "mjaumjau.se"
  subdomains = ["www"]
  ip = module.vps1.node.ip
  # ip6 = module.server.nodes.ip6
}

# Add DNS servers to opentofu output.
output "ns" {
  value = {
    "${module.vps1.node.domain}" = module.dns_mjaumjau_se.ns
  }
}

# Add all node information to output for `terraflake`.
output "terraflake" {
  # value = [module.vps1.node, module.node2.node]
  value = module.vps1.node
}
