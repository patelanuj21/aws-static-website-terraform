provider "aws" {
  region = var.region
}

# Create S3 bucket for the main website
resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.fqdn
  # acl           = "private"
  force_destroy = true

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.fqdn])
    Phase     = var.project_phase
  }
}

# Block all public access for the main bucket
resource "aws_s3_bucket_public_access_block" "block-website_bucket-public-access" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload website's index.html to the main S3 website bucket
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "index.html"
  source = "${path.module}/website_assets/index.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = "${path.module}/website_assets/index.html"
}

# Upload website's error.html to the main S3 website bucket
resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "error.html"
  source = "${path.module}/website_assets/error.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = "${path.module}/website_assets/error.html"
}

# Create S3 bucket for the redirect website
resource "aws_s3_bucket" "redirect_bucket" {
  for_each      = var.redirect_sites
  bucket        = each.value
  # acl           = "private"
  force_destroy = true

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, each.key])
    Phase     = var.project_phase
  }
}

# Block all public access for the redirect buckets
resource "aws_s3_bucket_public_access_block" "block-redirect_bucket-public-access" {
  for_each                = var.redirect_sites
  bucket                  = aws_s3_bucket.redirect_bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable static website hosting for redirect buckets and enable http redirects to the main site
resource "aws_s3_bucket_website_configuration" "redirect_bucket-public-access" {
  for_each                = var.redirect_sites
  bucket                  = aws_s3_bucket.redirect_bucket[each.key].id

  redirect_all_requests_to {
      host_name = var.fqdn
      protocol  = "http"
  }
}

# Create an S3 bucket to store logs
resource "aws_s3_bucket" "log_bucket" {
  bucket        = var.log_bucket
  # acl           = "private"
  force_destroy = true

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.log_bucket])
    Phase     = var.project_phase
  }
}

# Create a logs directory to store access logs in S3
resource "aws_s3_bucket_object" "logs_directory" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "private"
  key    = "logs/"
  source = "/dev/null"
}

# Block all public access for the logs bucket
resource "aws_s3_bucket_public_access_block" "block-logs_bucket-public-access" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# #  Create CloudFront distribution
# resource "aws_cloudfront_distribution" "website_distribution" {
#   enabled = true
#   logging_config {
#     include_cookies = false
#     bucket          = aws_s3_bucket.website_bucket.bucket_domain_name
#     prefix          = "logs"
#   }
#   aliases             = [aws_s3_bucket.website_bucket.bucket] # Needs to be replaced with variable
#   default_root_object = "index.html"

#   origin {
#     domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
#     origin_id   = aws_s3_bucket.website_bucket.bucket_regional_domain_name

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
#     }
#   }

#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
#     viewer_protocol_policy = "redirect-to-https"

#     forwarded_values {
#       headers      = []
#       query_string = true

#       cookies {
#         forward = "all"
#       }
#     }
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate.website_certificate.arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2018"
#   }

#   #   viewer_certificate {
#   #     cloudfront_default_certificate = true
#   #   }

#   tags = {
#     Environment = "Dev"
#   }
# }

# resource "aws_cloudfront_origin_access_identity" "oai" {
#   comment = "${aws_s3_bucket.website_bucket.bucket}-OAI"
# }

# resource "aws_s3_bucket_policy" "cloudfront_s3_bucket_policy" {
#   bucket = aws_s3_bucket.website_bucket.id
#   policy = data.aws_iam_policy_document.cloudfront_s3_bucket_policy.json
# }



# resource "aws_acm_certificate" "website_certificate" {
#   provider                  = aws.us-east-1
#   domain_name               = aws_s3_bucket.website_bucket.bucket
#   subject_alternative_names = [aws_s3_bucket.website_bucket.bucket] # Needs to be replaced with variable
#   validation_method         = "DNS"
#   tags = {
#     Environment = "Dev"
#   }
# }

# resource "aws_route53_record" "certvalidation" {
#   for_each = {
#     for domain in aws_acm_certificate.website_certificate.domain_validation_options : domain.domain_name => {
#       name   = domain.resource_record_name
#       record = domain.resource_record_value
#       type   = domain.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.website_zone.zone_id
# }

# resource "aws_acm_certificate_validation" "certvalidation" {
#   provider                = aws.us-east-1
#   certificate_arn         = aws_acm_certificate.website_certificate.arn
#   validation_record_fqdns = [for r in aws_route53_record.certvalidation : r.fqdn]
# }

# resource "aws_route53_zone" "website_zone" {
#   name = "anujpatel.net" # Needs to be replaced with variable
# }

# resource "aws_route53_record" "website_url" {
#   name    = aws_s3_bucket.website_bucket.bucket # Needs to be replaced with variable
#   zone_id = aws_route53_zone.website_zone.zone_id
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.website_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
#     evaluate_target_health = true
#   }
# }



# # Create Code Commit Repo
# resource "aws_codecommit_repository" "website_git_repo" {
#   repository_name = "MyStaticWebsite" # Needs to be replaced with variable
#   tags = {
#     Name        = "My Website repository"
#     Environment = "Dev"
#   }
# }