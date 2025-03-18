resource "google_secret_manager_secret" "github-secret" {
  project   = var.project_name
  secret_id = "github-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "github-secret" {
  secret      = google_secret_manager_secret.github-secret.id
  secret_data = var.github_key
}

data "google_iam_policy" "p4sa-secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = google_secret_manager_secret.github-secret.project
  secret_id   = google_secret_manager_secret.github-secret.id
  policy_data = data.google_iam_policy.p4sa-secretAccessor.policy_data
}

resource "google_cloudbuildv2_connection" "github" {
  name     = "github-connection"
  location = "europe-west1"

  github_config {
    app_installation_id = var.github_app_id
     authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github-secret.id
    }
  }
}

resource "google_cloudbuildv2_repository" "games-api-repo" {
  location          = "europe-west1"
  name              = "games-api-repo"
  parent_connection  = google_cloudbuildv2_connection.github.id
  remote_uri        = "https://github.com/Cuerry/games-api.git"
}

resource "google_cloudbuildv2_repository" "games-ui-repo" {
  location          = "europe-west1"
  name              = "games-ui-repo"
  parent_connection  = google_cloudbuildv2_connection.github.id
  remote_uri        = "https://github.com/Cuerry/games-ui.git"
}

resource "google_service_account" "cloudbuild_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "cloudbuild-sa"
  description  = "Cloud build service account"
}

resource "google_project_iam_binding" "cloudbuild_roles" {
  project = var.project_name
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_artifact_registry" {
  project = var.project_name
  role    = "roles/artifactregistry.writer"
  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_cloud_run" {
  project = var.project_name
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_cloud_run_developer" {
  project = var.project_name
  role    = "roles/run.developer"
  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_logs_writer" {
  project = var.project_name
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
  ]
}

resource "google_cloudbuild_trigger" "games-api-repo-trigger" {
  name     = "games-api-trigger"
  location = "europe-west1"

  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.games-api-repo.id
    push {
      branch = "main"
    }
  }

  build {
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
   step {
      id   = "Build"
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "--no-cache", "-t", "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-api:latest", "."]
    }
    step {
      id   = "Push"
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-api:latest"]
    }
    step {
      id         = "Deploy"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      entrypoint = "gcloud"
      args       = ["run", "services", "update", "games-api", "--platform=managed", "--image=europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-api:latest", "--labels=managed-by=gcp-cloud-build-deploy-cloud-run,commit-sha=$COMMIT_SHA,gcb-build-id=$BUILD_ID", "--region=europe-west1", "--quiet"]
    }
  }

}

resource "google_cloudbuild_trigger" "games-ui-repo-trigger" {
  name     = "games-ui-trigger"
  location = "europe-west1"

  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.games-ui-repo.id
    push {
      branch = "main"
    }
  }

  build {
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
   step {
      id   = "Build"
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "--no-cache", "-t", "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-ui:latest", "."]
    }
    step {
      id   = "Push"
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-ui:latest"]
    }
    step {
      id         = "Deploy"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      entrypoint = "gcloud"
      args       = ["run", "services", "update", "games-ui", "--platform=managed", "--image=europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-ui:latest", "--labels=managed-by=gcp-cloud-build-deploy-cloud-run,commit-sha=$COMMIT_SHA,gcb-build-id=$BUILD_ID", "--region=europe-west1", "--quiet"]
    }
  }

}