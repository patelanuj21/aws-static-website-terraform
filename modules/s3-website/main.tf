provider "aws" {
  region = var.region
}

# Create S3 bucket for the main website
resource "aws_s3_bucket" "website_bucket" {
  bucket = one(var.fqdn)
  # acl           = "private"
  force_destroy = true

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.fqdn[0]])
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
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content_type = "text/html"
  source       = "${path.module}/website_assets/index.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = "filemd5(${path.module}/website_assets/index.html)"
}

# Upload website's error.html to the main S3 website bucket
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "error.html"
  content_type = "text/html"
  source       = "${path.module}/website_assets/error.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = "filemd5(${path.module}/website_assets/error.html)"
}

# Create S3 bucket for the redirect website
resource "aws_s3_bucket" "redirect_bucket" {
  for_each = toset(var.redirect_sites)
  bucket   = each.value
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
  for_each                = toset(var.redirect_sites)
  bucket                  = aws_s3_bucket.redirect_bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable static website hosting for redirect buckets and enable http redirects to the main site
resource "aws_s3_bucket_website_configuration" "redirect_bucket-public-access" {
  for_each = toset(var.redirect_sites)
  bucket   = aws_s3_bucket.redirect_bucket[each.key].id

  redirect_all_requests_to {
    host_name = var.fqdn[0]
    protocol  = "http"
  }
}

# Create an S3 bucket to store logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket
  # acl           = "private"
  force_destroy = true

  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.log_bucket])
    Phase     = var.project_phase
  }
}

# Create a logs directory to store access logs in S3
resource "aws_s3_object" "logs_directory" {
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