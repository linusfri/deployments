resource "hcloud_ssh_key" "main" {
  name       = "main_ssh"
  public_key = var.ssh_pub
}

# Prod
resource "hcloud_server" "nixos" {
  name        = "hetzvps"
  image       = "ubuntu-22.04"
  server_type = "cpx32"
  datacenter  = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
  labels = {
    "label" : "seed"
  }
  lifecycle {
    ignore_changes  = [ssh_keys]
    prevent_destroy = true
  }
}

resource "hcloud_rdns" "rdns4" {
  server_id  = hcloud_server.nixos.id
  ip_address = hcloud_server.nixos.ipv4_address
  dns_ptr    = "mail.friikod.se"
}

resource "hcloud_rdns" "rdns6" {
  server_id  = hcloud_server.nixos.id
  ip_address = hcloud_server.nixos.ipv6_address
  dns_ptr    = "mail.friikod.se"
}

# Stage
resource "hcloud_server" "nixos_stage" {
  name        = "hetzvpsstage"
  image       = "ubuntu-24.04"
  server_type = "cpx22"
  datacenter  = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
  labels = {
    "label" : "seed"
  }
  lifecycle {
    ignore_changes  = [ssh_keys]
    prevent_destroy = true
  }
}