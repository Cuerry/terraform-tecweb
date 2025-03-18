variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_number" {
  description = "Project Number"
  type        = number
}

variable "db_password" {
  description = "SQL DB Password"
  type        = string
}

variable "cloud_sql_instance" {
  description = "SQL Connection Name"
  type = string
}

resource "google_cloud_run_v2_service" "games-api" {
  name     = "games-api"
  location = "europe-west1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  template {
    timeout                          = "30s"
    max_instance_request_concurrency = 300

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-api:latest"
      ports {
        container_port = 50007
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "DB_HOST"
        value = "/cloudsql/${var.cloud_sql_instance}"
      }
      env {
        name  = "DB_USER"
        value = "deisi"
      }
      env {
        name  = "DB_PASS"
        value = var.db_password
      }
      env {
        name  = "DB_NAME"
        value = "games-db"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.cloud_sql_instance]
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth-games-api" {
  location = "europe-west1"

  service     = google_cloud_run_v2_service.games-api.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_v2_service" "games-ui" {
  name     = "games-ui"
  location = "europe-west1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  template {
    timeout                          = "30s"
    max_instance_request_concurrency = 300

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "europe-west1-docker.pkg.dev/${var.project_name}/games-repo/games-ui:latest"
      ports {
        container_port = 3000
      }

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "API_URL"
        value = google_cloud_run_v2_service.games-api.uri
      }
    }
  }
}

resource "google_cloud_run_service_iam_policy" "noauth-games-ui" {
  location = "europe-west1"

  service     = google_cloud_run_v2_service.games-ui.name
  policy_data = data.google_iam_policy.noauth.policy_data
}