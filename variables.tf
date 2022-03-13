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
  type = list(string)
}