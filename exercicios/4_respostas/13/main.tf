provider "aws" {
  region = "us-west-2"
}

backend "s3" {
    bucket = "meu-bucket-tf-state"
    key    = "terraform/state.tfstate"
    region = "us-west-2"
}