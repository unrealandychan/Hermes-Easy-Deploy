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

  tags = ["hermes-agent"]

  labels = {
    project = "Hermes-Agent-Cloud"
  }
}
