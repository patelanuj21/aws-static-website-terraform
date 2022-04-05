variable "region" {
  type    = string
  default = "us-east-1"
}

variable "is_terraform" {
  type    = bool
  default = true
}

variable "project_name" {
  type = string
}

variable "name" {
  type = string
}

variable "project_phase" {
  type = string
}

variable "git_user" {
  type = string
}

variable "fqdn" {
  type = list(any)
}