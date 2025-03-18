resource "google_sql_database_instance" "this" {
  name             = "games-instance"
  database_version = "POSTGRES_15"
  region           = "europe-west1"

  deletion_protection = false

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "games_user" {
  instance = google_sql_database_instance.this.name
  name     = "deisi"
  password = var.db_password
}

resource "google_sql_database" "games_db" {
  name     = "games-db"
  instance = google_sql_database_instance.this.name
}

output "cloud_sql_instance" {
  value = google_sql_database_instance.this.connection_name
}