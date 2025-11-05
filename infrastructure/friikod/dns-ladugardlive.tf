resource "cloudflare_zone" "ladugardlive" {
  name = "ladugardlive.se"
  account = { id = var.cloudflare_id }

  lifecycle {
    prevent_destroy = true
  }
}

# IPV4
resource "cloudflare_dns_record" "ladugardlive" {
  zone_id = cloudflare_zone.ladugardlive.id
  name    = cloudflare_zone.ladugardlive.name
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "ladugardlive-subdomain-www" {
  zone_id = cloudflare_zone.ladugardlive.id
  name    = "www.ladugardlive.se"
  content = hcloud_server.nixos.ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
}


# IPV6
resource "cloudflare_dns_record" "ladugardlive-default6" {
  zone_id = cloudflare_zone.ladugardlive.id
  name    = cloudflare_zone.ladugardlive.name
  content = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "ladugardlive-subdomain6-www" {
  zone_id = cloudflare_zone.ladugardlive.id
  name    = "www.ladugardlive.se"
  content = hcloud_server.nixos.ipv6_address
  type    = "AAAA"
  proxied = true
  ttl     = 1
}

output "ladugardlive-ns" {
  value = cloudflare_zone.ladugardlive.name_servers
}