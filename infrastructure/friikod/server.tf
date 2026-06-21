resource "hcloud_ssh_key" "main" {
  name       = "main_ssh"
  public_key = var.ssh_pub
}

# Prod
resource "hcloud_server" "nixos" {
  name        = "hetzvps"
  image       = "ubuntu-22.04"
  server_type = "cpx32"
  location    = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
  labels = {
    "label" : "seed"
  }
  lifecycle {
    ignore_changes  = [ssh_keys, location]
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
  location    = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
  labels = {
    "label" : "seed"
  }
  lifecycle {
    ignore_changes  = [ssh_keys, location]
    prevent_destroy = true
  }
}

# Stage2
# resource "hcloud_server" "nixos_stagesec" {
#   name        = "hetzvpsstagesec"
#   image       = "400063552"
#   server_type = "cpx22"
#   location    = "hel1"
#   public_net {
#     ipv4_enabled = true
#     ipv6_enabled = true
#   }
#   ssh_keys = [hcloud_ssh_key.main.id]
#   labels = {
#     "label" : "seed"
#   }
#   lifecycle {
#     ignore_changes  = [ssh_keys, location]
#     prevent_destroy = false
#   }
# }

# Storagebox
resource "hcloud_storage_box" "backups" {
  name             = "storagebox-backups"
  storage_box_type = "bx11"
  location         = "hel1"
  password         = var.storagebox_backups_password

  labels = {
    "type" : "backups"
  }

  access_settings = {
    reachable_externally = true
    samba_enabled        = false
    ssh_enabled          = true
    webdav_enabled       = false
    zfs_enabled          = false
  }

  delete_protection = true
}
