resource "google_compute_firewall" "hermes_ssh" {
  name    = "hermes-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["hermes-agent"]
  description   = "Allow SSH to Hermes instance from deployer IP only"
}

resource "google_compute_firewall" "hermes_gateway" {
  name    = "hermes-allow-gateway"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["hermes-agent"]
  description   = "Allow Hermes gateway port from deployer IP only"
}
