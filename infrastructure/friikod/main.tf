output "nodes" {
  value = {
    friikod = {
      provider = "hetznercloud"
      name     = hcloud_server.nixos.name
      ip       = hcloud_server.nixos.ipv4_address
      ip6      = hcloud_server.nixos.ipv6_address
      ssh_key  = var.ssh_pub
      label    = "friikod"
      domains = {
        "friikod"          = "friikod.se"
        "ladugardlive"     = "ladugardlive.se"
        "calc-api"         = "calc.friikod.se"
        "auth-server"      = "auth-server.friikod.se"
        "strapi"           = "strapi.friikod.se"
        "next"             = "next.friikod.se"
        "plex"             = "plex.friikod.se"
        "nextcloud"        = "nextcloud.friikod.se"
        "jellyfin"         = "jellyfin.friikod.se"
        "keycloak"         = "keycloak.friikod.se"
        "elin"             = "elin.friikod.se"
        "ladugardlive-web" = "web.ladugardlive.se"
      }
    }
  }
}