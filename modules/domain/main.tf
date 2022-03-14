provider "aws" {
  region = var.region
}

#  Looks for the Roure 53 Zone
data "aws_route53_zone" "this" {
  name = var.name
}

# Creates SSL Certificate Requests for the requested SANs
resource "aws_acm_certificate" "certificates" {
  domain_name       = var.fqdn
  subject_alternative_names = ["*.${var.name}", var.name]
  validation_method = "DNS"

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase,var.name])
    Phase     = var.project_phase
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Creates Route 53 record for the sites
resource "aws_route53_record" "certvalidation" {
  for_each = {
    for domain in aws_acm_certificate.certificates.domain_validation_options : domain.domain_name => {
      name   = domain.resource_record_name
      record = domain.resource_record_value
      type   = domain.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

# Validates the SSL Certificates using Route 53
resource "aws_acm_certificate_validation" "certvalidation" {
  certificate_arn         = aws_acm_certificate.certificates.arn
  validation_record_fqdns = [for r in aws_route53_record.certvalidation : r.fqdn]
}