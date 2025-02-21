provider "google" {
  project = "toolbox-sandbox-388523"
  region  = "us-central1"
}

resource "google_storage_bucket" "my_bucket" {
  name          = "my-explicit-dep-bucket"
  location      = "US"
  storage_class = "STANDARD"
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.my_bucket.name
  source = "function-source.zip"

  depends_on = [google_storage_bucket.my_bucket] # Explicit dependency
}

resource "google_cloudfunctions_function" "my_function" {
  name        = "my-explicit-function"
  runtime     = "python39"
  region      = "us-central1"
  entry_point = "hello_world"

  source_archive_bucket = google_storage_bucket.my_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name

  trigger_http = true

  depends_on = [google_storage_bucket_object.function_source] # Explicit dependency
}

output "function_url" {
  value = google_cloudfunctions_function.my_function.https_trigger_url
}
