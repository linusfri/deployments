# Docs: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/

resource "cloudflare_zero_trust_tunnel_cloudflared" "auth_server" {
  account_id = var.cloudflare_id
  name       = "auth-server-tunnel"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "auth_server_token" {
  account_id = var.cloudflare_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.auth_server.id
}

resource "cloudflare_dns_record" "subdomain-authserver-local" {
  zone_id = cloudflare_zone.default.id
  name    = "auth-server-local"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.auth_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "auth_server_config" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.auth_server.id
  account_id = var.cloudflare_id
  config = {
    ingress = [
      {
        hostname = "auth-server-local.friikod.se"
        service  = "http://127.0.0.1:8000"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

output "tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.auth_server_token.token
  sensitive = true
}
