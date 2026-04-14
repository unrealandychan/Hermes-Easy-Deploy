# Helper locals to simplify conditional secret + IAM resources
locals {
  secrets = {
    openrouter = { id = "hermes-openrouter-api-key", value = var.openrouter_api_key }
    openai     = { id = "hermes-openai-api-key",     value = var.openai_api_key }
    anthropic  = { id = "hermes-anthropic-api-key",  value = var.anthropic_api_key }
    gemini     = { id = "hermes-gemini-api-key",     value = var.gemini_api_key }
  }
  # Only create resources for keys that were actually provided
  active_secrets = {
    for k, v in local.secrets : k => v if v.value != ""
  }
}

resource "google_secret_manager_secret" "hermes" {
  for_each  = local.active_secrets
  secret_id = each.value.id
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    project = "hermes-deploy"
  }
}

resource "google_secret_manager_secret_version" "hermes" {
  for_each    = local.active_secrets
  secret      = google_secret_manager_secret.hermes[each.key].id
  secret_data = each.value.value
}

# Grant the VM service account accessor rights to each secret
resource "google_secret_manager_secret_iam_member" "hermes" {
  for_each  = local.active_secrets
  secret_id = google_secret_manager_secret.hermes[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.hermes.email}"
}
