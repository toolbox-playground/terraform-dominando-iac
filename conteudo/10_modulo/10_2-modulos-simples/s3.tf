provider "aws" {
  region = "us-east-1"
}

module "s3_bucket" {
  source = "./modulo"
}

module "s3_bucketjean" {
  source = "./modulo"
}

module "s3_bucketjo" {
  source = "./modulo"
}

output "bucket_config" {
  value = module.s3_bucket.bucket_config.bucket_name
}
