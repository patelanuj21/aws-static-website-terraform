variable "main_region" {
  type    = string
  default = "us-east-1"
}

variable "main_project_name" {
  type = string
}

variable "main_domain" {
  type = string
}

variable "main_fqdn" {
  type = list(any)
}

variable "main_log_bucket" {
  type = string
}

variable "main_redirect_sites" {
  type = list(any)
}

variable "main_git_user" {
  type = string
}