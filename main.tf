terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.main_region
}

module "domain" {
  source       = "./modules/domain"
  region       = var.main_region
  project_name = var.main_project_name
  name         = var.main_domain
  is_terraform = true
}