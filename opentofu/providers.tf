terraform {
  backend "s3" {
    bucket                      = "tfstatebucket"
    key                         = "terraform.tfstate"
    region                      = "eeur"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints                   = { s3 = "https://${var.cloudflare_id}.r2.cloudflarestorage.com" }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
