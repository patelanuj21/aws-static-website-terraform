output "website_bucket" {
  value = aws_s3_bucket.website_bucket.bucket
}

output "website_id" {
  value = aws_s3_bucket.website_bucket.id
}

output "region" {
  value = aws_s3_bucket.website_bucket.region
}

output "website_arn" {
  value = aws_s3_bucket.website_bucket.arn
}

output "website_bucket_regional_domain_name" {
  value = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

output "logs_bucket_domain_name" {
  value = aws_s3_bucket.log_bucket.bucket_domain_name
}

output "redirect_bucket_name" {
  value = toset([
    for redirect_bucket in aws_s3_bucket.redirect_bucket : redirect_bucket.bucket
  ])
}

output "redirect_buckets" {
  value = tomap(aws_s3_bucket.redirect_bucket)
}
