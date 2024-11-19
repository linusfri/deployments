variable "account_id" {}
variable "domain" {}
variable "subdomains" {}
variable "ip" {}
variable "ip6" {
  default = ""
}
variable "mx" {
  default = ""
}
variable "dkim_txt" {
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
      source = "registry.terraform.io/cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  subdomains = concat(var.mx != "" ? [var.mx] : [], var.subdomains)
}

resource "cloudflare_zone" "default" {
  zone = var.domain
  account_id = var.account_id
  jump_start = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "default" {
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.zone
  value   = var.ip
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "subdomains" {
  count   = length(local.subdomains)
  zone_id = cloudflare_zone.default.id
  name    = local.subdomains[count.index]
  value   = var.ip
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "default6" {
  count   = var.ip6 != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.zone
  value   = var.ip6
  type    = "AAAA"
  ttl     = 1
}

resource "cloudflare_record" "subdomains6" {
  count   = var.ip6 != "" ? length(local.subdomains) : 0
  zone_id = cloudflare_zone.default.id
  name    = local.subdomains[count.index]
  value   = var.ip6
  type    = "AAAA"
  ttl     = 1
}

resource "cloudflare_record" "mx" {
  count   = var.mx != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.zone
  value   = "${var.mx}.${cloudflare_zone.default.zone}"
  type    = "MX"
  ttl     = 1
}

resource "cloudflare_record" "dkim" {
  count   = (var.mx != "" && var.dkim_txt != "") ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = "${var.mx}._domainkey.${cloudflare_zone.default.zone}"
  value   = var.dkim_txt
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "spf" {
  count   = var.mx != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = cloudflare_zone.default.zone
  value   = "v=spf1 mx a ip4:${var.ip}${var.ip6 != "" ? " ip6:${var.ip6}" : ""} -all"
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "dmarc" {
  count   = var.mx != "" ? 1 : 0
  zone_id = cloudflare_zone.default.id
  name    = "_dmarc.${cloudflare_zone.default.zone}"
  value   = "v=DMARC1; p=reject; rua=mailto:postmaster@${cloudflare_zone.default.zone}; ruf=mailto:postmaster@${cloudflare_zone.default.zone}; sp=reject; fo=1; ri=86400"
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "extra" {
  count    = length(var.extra)
  zone_id  = cloudflare_zone.default.id
  name     = var.extra[count.index].name
  type     = var.extra[count.index].type
  value    = var.extra[count.index].value
  priority = var.extra[count.index].priority
  ttl      = 1
}


output "ns" {
  value = cloudflare_zone.default.name_servers
}
