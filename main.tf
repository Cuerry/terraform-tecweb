module "network" {
  source        = "./modules/network"
}

module "compute_engine" {
  source = "./modules/compute_engine"
}

module "sql_database" {
  source = "./modules/sql_database"
  db_password = var.db_password
}

module "repository" {
  source = "./modules/repository"
}

module "cloud_build" {
  source = "./modules/cloud_build"
  project_name = var.project_name
  project_number = var.project_number
  github_app_id = var.github_app_id
  github_key = var.github_key
}

module "cloud_run" {
  source = "./modules/cloud_run"
  project_name = var.project_name
  project_number = var.project_number
  db_password = var.db_password
  cloud_sql_instance = module.sql_database.cloud_sql_instance
}