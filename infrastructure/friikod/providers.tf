terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "opentofu/hcloud"
      version = "~> 1.66.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
