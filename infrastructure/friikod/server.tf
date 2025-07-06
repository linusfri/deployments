resource "hcloud_ssh_key" "main" {
  name       = "main_ssh"
  public_key = var.ssh_pub
}

resource "hcloud_server" "nixos" {
  name        = "hetzvps"
  image       = "ubuntu-22.04"
  server_type = "cpx31"
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
    ignore_changes = [ssh_keys]
    prevent_destroy = true
  }
}
