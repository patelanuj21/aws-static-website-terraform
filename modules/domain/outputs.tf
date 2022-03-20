output "website_certificate_arn" {
  value = aws_acm_certificate.certificates.arn
}

output "domain_zone_id" {
  value = data.aws_route53_zone.this.zone_id
}