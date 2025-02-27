provider "aws" {
  region = "us-east-1"
}

module "s3_buckets" {
  source = "./modulo"

  for_each = {
    "app-data"     = { versioning = true, encryption = true, public_access = false }
    "user-backups" = { versioning = true, encryption = false, public_access = false }
    "audit-logs"   = { versioning = false, encryption = true, public_access = true }
  }

  bucket_name         = "${each.key}-123456789"
  enable_versioning   = each.value.versioning
  enable_encryption   = each.value.encryption
  block_public_access = !each.value.public_access
}

# **Saída com os nomes dos buckets criados**
output "bucket_names" {
  value = [for b in module.s3_buckets : b.bucket_name]
}
