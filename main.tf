terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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
  project_phase  = local.main_project_phase
  fqdn           = var.main_fqdn
  redirect_sites = var.main_redirect_sites
  name         = var.main_domain
  is_terraform = true
}

module "website" {
  source         = "./modules/s3-website"
  region         = var.main_region
  name           = var.main_domain
  fqdn           = var.main_fqdn
  redirect_sites = var.main_redirect_sites
  project_name   = var.main_project_name
  project_phase  = local.main_project_phase
  log_bucket     = var.main_log_bucket
  is_terraform   = true
}