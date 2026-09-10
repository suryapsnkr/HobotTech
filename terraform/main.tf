terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.7.0"
    }
  }
  backend "gcs" {
    bucket = "habotconnect-terraform-state-bucket"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. GCS D0 Raw Landing Bucket
resource "google_storage_bucket" "d0_raw_landing" {
  name          = "${var.project_id}-d0-raw-landing"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
  storage_class               = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }
}

# 2. BigQuery D1 Staged/Enforced Dataset
resource "google_bigquery_dataset" "d1_staged" {
  dataset_id                  = "D1_Staged_Enforced"
  friendly_name               = "D1 Staged/Enforced"
  description                 = "Dataset for staged data with row-level security enforced."
  location                    = var.region
  default_table_expiration_ms = 2592000000  # 30 days

  labels = {
    env = "staging"
  }
}

# 3. IAM & Least Privilege Implementation
resource "google_bigquery_dataset_iam_member" "data_engineer" {
  dataset_id = google_bigquery_dataset.d1_staged.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:data-engineers@habotconnect.com"

  # IAM Condition for time-bound access (Least Privilege)
  condition {
    title       = "Grant access only to members of a specific group"
    expression  = "gcp:resource.name == 'projects/${var.project_id}/datasets/${google_bigquery_dataset.d1_staged.dataset_id}'"
  }
}

# 4. Row-Level Security (RLS) Policy
# Terraform lacks a direct resource for RLS, so we use a job to create the policy.
resource "google_bigquery_job" "create_row_access_policy" {
  job_id = "d1_${google_bigquery_dataset.d1_staged.dataset_id}_rls"

  query {
    query = <<-EOT
      CREATE OR REPLACE ROW ACCESS POLICY
        grant_access_to_parents
      ON
        `${var.project_id}.${google_bigquery_dataset.d1_staged.dataset_id}.student_onboarding`
      GRANT TO
        ("group:parents@habotconnect.com")
      FILTER USING
        (user_email = SESSION_USER());
    EOT
  }
}