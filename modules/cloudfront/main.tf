module "website" {
  source         = "../s3-website"
  region         = var.region
  name           = var.name
  fqdn           = var.fqdn
  redirect_sites = var.redirect_sites
  project_name   = var.project_name
  project_phase  = var.project_phase
  log_bucket     = var.log_bucket
  is_terraform   = true
}

module "domain" {
  source         = "../domain"
  region         = var.region
  project_name   = var.project_name
  project_phase  = var.project_phase
  fqdn           = var.fqdn
  redirect_sites = var.redirect_sites
  name           = var.name
  is_terraform   = true
}

# Creates A Record for the redirect buckets
resource "aws_route53_record" "redirect_url" {
  for_each = module.website.redirect_buckets
  name     = each.value.bucket
  zone_id  = module.domain.domain_zone_id
  type     = "A"

  alias {
    name                   = each.value.website_domain
    zone_id                = each.value.hosted_zone_id
    evaluate_target_health = false
  }
}

# Fetch the policy that only allows access to CloudFront 
data "aws_iam_policy_document" "cloudfront_s3_bucket_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      module.website.website_arn,
      "${module.website.website_arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

#  Create CloudFront distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled = true
  logging_config {
    include_cookies = false
    bucket          = module.website.logs_bucket_domain_name
    prefix          = "logs"
  }

  aliases             = concat(sort(var.redirect_sites), sort(var.fqdn))
  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
  }

  origin {
    origin_id   = "${module.website.website_bucket}.s3.${module.website.region}.amazonaws.com"
    domain_name = "${module.website.website_bucket}.s3.${module.website.region}.amazonaws.com"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${module.website.website_bucket}.s3.${module.website.region}.amazonaws.com"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers      = []
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.domain.website_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.fqdn[0], "CloudFront"])
    Phase     = var.project_phase
  }
}

# Creates OAI for the CloudFront distribution
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "${module.website.website_bucket}-OAI"
}

resource "aws_s3_bucket_policy" "cloudfront_s3_bucket_policy" {
  bucket = module.website.website_id
  policy = data.aws_iam_policy_document.cloudfront_s3_bucket_policy.json
}

# Creates A Record for the CloudFront distribution
resource "aws_route53_record" "website_url" {
  name    = module.website.website_bucket
  zone_id = module.domain.domain_zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}