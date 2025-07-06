output "nodes" {
  value = {
    friikod = {
      provider = "hcloud"
      name     = hcloud_server.nixos.hostname
      ip       = hcloud_server.nixos.ipv4_address
      ip6      = hcloud_server.nixos.ipv6_address
      ssh_key  = var.ssh_pub
      label    = "friikod"
      domains = {
        friikod   = "friikod.se"
      }
    }
  }
}