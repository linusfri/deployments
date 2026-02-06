resource "cloudflare_r2_bucket" "tfstatebucket" {
  account_id    = var.cloudflare_id
  name          = "tfstatebucket"
  location      = "eeur"
  storage_class = "Standard"
}
