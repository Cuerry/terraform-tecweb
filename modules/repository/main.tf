resource "google_artifact_registry_repository" "this" {
  location      = "europe-west1"
  repository_id = "games-repo"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      older_than = "172800s"
    }
  }

  cleanup_policies {
    id     = "keep-tagged-latest"
    action = "KEEP"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["latest"]
    }
  }
}