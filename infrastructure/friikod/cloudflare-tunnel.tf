# Docs: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/

resource "cloudflare_zero_trust_tunnel_cloudflared" "handygleam" {
  account_id = var.cloudflare_id
  name       = "handy-gleam-tunnel"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "handygleam_token" {
  account_id = var.cloudflare_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.handygleam.id
}

resource "cloudflare_dns_record" "subdomain-handygleam-local" {
  zone_id = cloudflare_zone.default.id
  name    = "handy-gleam-local"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.handygleam.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "handygleam_config" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.handygleam.id
  account_id = var.cloudflare_id
  config = {
    ingress = [
      {
        hostname = "handy-gleam-local.friikod.se"
        service  = "http://127.0.0.1:8000"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

output "tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.handygleam_token.token
  sensitive = true
}
