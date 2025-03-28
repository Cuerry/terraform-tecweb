variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_number" {
  description = "Project Number"
  type        = number
}

variable "region" {
  description = "Deploy region"
  type        = string
}

variable "db_password" {
  description = "SQL DB Password"
  type        = string
}

variable "github_key" {
  description = "Github Key"
  type        = string
}

variable "github_app_id" {
  description = "Github APP ID"
  type        = number
}