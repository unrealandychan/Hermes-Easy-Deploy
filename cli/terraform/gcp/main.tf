terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Dedicated service account — only needs Secret Manager access
resource "google_service_account" "hermes" {
  account_id   = "hermes-agent-sa"
  display_name = "Hermes Agent Service Account"
}

resource "google_compute_instance" "hermes" {
  name         = "hermes-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    # Assign an ephemeral public IP
    access_config {}
  }

  service_account {
    email  = google_service_account.hermes.email
    # cloud-platform scope is required for Secret Manager API access
    scopes = ["cloud-platform"]
  }

  # bootstrap.sh is a Terraform templatefile. The VM pulls API keys from
  # Secret Manager via its Service Account at boot — no secrets in metadata.
  metadata = {
    startup-script = templatefile("${path.module}/bootstrap.sh", {
      HERMES_CLOUD  = "gcp"
      AWS_REGION    = ""
      SSM_PREFIX    = ""
      AZURE_KV_NAME = ""
      GCP_PROJECT   = var.project_id
    })
  }

  tags = ["hermes-agent"]

  labels = {
    project = "hermes-deploy"
  }
}
