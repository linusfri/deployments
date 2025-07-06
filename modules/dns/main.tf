variable "account_id" {}
variable "domain" {}
variable "subdomains" {
  type        = map(string)
  default     = {}
  description = "Map of subdomains to their unique IP addresses"
}
variable "ip" {}
variable "ip6" {
  default = ""
}

variable "extra" {
  type = list(object({
    name     = string
    type     = string
    value    = string
    priority = string
  }))
  default = []
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

resource "cloudflare_zone" "default" {
  account = {
    id = var.account_id
  }
  name = var.domain
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "default" {
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.name
  content   = var.ip
  type    = "A"
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomains" {
  for_each = var.subdomains
  
  zone_id  = cloudflare_zone.default.id
  name     = each.key
  content  = each.value
  type     = "A"
  ttl      = 1
}

resource "cloudflare_dns_record" "default6" {
  count   = var.ip6 != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.name
  content   = var.ip6
  type    = "AAAA"
  ttl     = 1
}

resource "cloudflare_dns_record" "subdomains6" {
  for_each = var.ip6 != "" ? var.subdomains : {}

  zone_id  = cloudflare_zone.default.id
  name     = each.key
  content  = each.value
  type     = "AAAA"
  ttl      = 1
}


resource "cloudflare_dns_record" "extra" {
  count    = length(var.extra)
  zone_id  = cloudflare_zone.default.id
  name     = var.extra[count.index].name
  type     = var.extra[count.index].type
  content    = var.extra[count.index].value
  priority = var.extra[count.index].priority
  ttl      = 1
}


output "ns" {
  value = cloudflare_zone.default.name_servers
}
