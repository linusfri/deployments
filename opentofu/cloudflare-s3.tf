resource "cloudflare_r2_bucket" "tfstatebucket" {
  account_id    = var.cloudflare_id
  name          = "tfstatebucket"
  location      = "eeur"
  storage_class = "Standard"
}

resource "cloudflare_r2_bucket" "nextcloudbucket" {
  account_id    = var.cloudflare_id
  name          = "nextcloudbucket"
  location      = "eeur"
  storage_class = "Standard"
}

resource "cloudflare_r2_bucket" "jellyfinbucket" {
  account_id    = var.cloudflare_id
  name          = "jellyfinbucket"
  location      = "eeur"
  storage_class = "Standard"
}
