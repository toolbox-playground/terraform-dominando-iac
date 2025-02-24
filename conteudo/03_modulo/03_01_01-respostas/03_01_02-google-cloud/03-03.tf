provider "google" {
  project = "toolbox-sandbox-388523"
  region  = "us-central1"
}

resource "google_storage_bucket" "default" {
  name     = "this-is-a-test"
  location = "US"

  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
