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
  content   = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain-www" {
  zone_id = cloudflare_zone.default.id
  name    = "www.friikod.se"
  content   = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}


# IPV6
resource "cloudflare_dns_record" "default6" {
  count   = hcloud_server.friikod.ipv6_address != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.name
  content   = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomain6-www" {
  zone_id = cloudflare_zone.default.id
  name    = "www.friikod.se"
  content   = hcloud_server.nixos.ipv6_address
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
  content    = local.extra[count.index].value
  priority = local.extra[count.index].priority
  ttl      = 1
}


output "ns" {
  value = cloudflare_zone.default.name_servers
}