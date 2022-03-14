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
  type = string
}

variable "project_phase" {
  type = string
}

variable "redirect_sites" {
  type = set(string)
}