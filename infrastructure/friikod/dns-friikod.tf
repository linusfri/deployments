resource "cloudflare_zone" "default" {
  name = "friikod.se"
  account = { id = var.cloudflare_id }

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  extra = [] 
}

# IPV4
resource "cloudflare_dns_record" "default" {
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.name
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-www" {
  zone_id = cloudflare_zone.default.id
  name    = "www.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-calc" {
  zone_id = cloudflare_zone.default.id
  name    = "calc.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-authserver" {
  zone_id = cloudflare_zone.default.id
  name    = "auth-server.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-strapi" {
  zone_id = cloudflare_zone.default.id
  name    = "strapi.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-next" {
  zone_id = cloudflare_zone.default.id
  name    = "next.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-nextcloud" {
  zone_id = cloudflare_zone.default.id
  name    = "nextcloud.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "subdomain-jellyfin" {
  zone_id = cloudflare_zone.default.id
  name    = "jellyfin.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "subdomain-keycloak" {
  zone_id = cloudflare_zone.default.id
  name    = "keycloak.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "subdomain-valheim" {
  zone_id = cloudflare_zone.default.id
  name    = "valheim.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "subdomain-elin" {
  zone_id = cloudflare_zone.default.id
  name    = "elin.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 3600
}

# Mail
resource "cloudflare_dns_record" "mail-ip4" {
  zone_id = cloudflare_zone.default.id
  name    = "mail.friikod.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 10800
}

resource "cloudflare_dns_record" "mail-ip6" {
  zone_id = cloudflare_zone.default.id
  name    = "mail.friikod.se"
  content = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = false
  ttl     = 10800
}

resource "cloudflare_dns_record" "default-mx" {
  zone_id  = cloudflare_zone.default.id
  content  = "mail.friikod.se"
  name     = "friikod.se"
  type     = "MX"
  priority = 10
  proxied  = false
  ttl      = 10800
}

resource "cloudflare_dns_record" "default-spf" {
  zone_id = cloudflare_zone.default.id
  content = "v=spf1 a:mail.friikod.se -all"
  name    = "friikod.se"
  type    = "TXT"
  proxied = false
  ttl     = 10800
}

resource "cloudflare_dns_record" "default-dkim" {
  zone_id = cloudflare_zone.default.id
  content = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEqsDnRTlJ5xdG3zUOJ3cZlopvwXMJYtILFbHPb5u5YMZoFCC/ZbCYfZaVmPy8sSlTVSAZIXMAjsz2c6RbTMolO5VCuLEvDSrYaNEJRCDtgqvNTy5HjYJNGGTQz5LQ+CAlMsxQYly4nFG/ePjvCr6QH5ZbfPQzbffK0A9V6IKEQwIDAQAB"
  name    = "mail._domainkey.friikod.se"
  type    = "TXT"
  proxied = false
  ttl     = 10800
}

resource "cloudflare_dns_record" "default-dmarc" {
  zone_id = cloudflare_zone.default.id
  content = "v=DMARC1; p=none"
  name    = "_dmarc.friikod.se"
  type    = "TXT"
  proxied = false
  ttl     = 10800
}

# IPV6
resource "cloudflare_dns_record" "default6" {
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.name
  content = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain6-www" {
  zone_id = cloudflare_zone.default.id
  name    = "www.friikod.se"
  content = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = true
  ttl     = 1
}


# For future reference if the records grow in number
# resource "cloudflare_dns_record" "subdomains6" {
#   for_each = hetzvps.nixos.ipv6_address != "" ? local.subdomains6 : {}

#   zone_id  = cloudflare_zone.default.id
#   name     = each.key
#   content  = each.value
#   type     = "AAAA"
#   ttl      = 1
# }

resource "cloudflare_dns_record" "extra" {
  count    = length(local.extra)
  zone_id  = cloudflare_zone.default.id
  name     = local.extra[count.index].name
  type     = local.extra[count.index].type
  content  = local.extra[count.index].value
  priority = local.extra[count.index].priority
  ttl      = 1
}


output "ns" {
  value = cloudflare_zone.default.name_servers
}