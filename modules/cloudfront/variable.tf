variable "region" {
  type    = string
  default = "us-east-1"
}

variable "is_terraform" {
  type = bool
}

variable "project_name" {
  type = string
}

variable "name" {
  type = string
}

variable "fqdn" {
  type = list(any)
}

variable "project_phase" {
  type = string
}

variable "log_bucket" {
  type = string
}

variable "redirect_sites" {
  type = list(any)
}