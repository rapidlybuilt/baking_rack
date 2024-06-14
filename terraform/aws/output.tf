output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "S3 bucket name that holds the files"
}

output "iam_role_arn" {
  value       = aws_iam_role.s3_bucket_uploader.arn
  description = "ARN of the role available for GitHub Actions to manages files on the AWS S3 bucket"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.main.website_endpoint
  description = "S3 bucket's website endpoint."
}

output "handshake" {
  value       = local.handshake
  description = "Allows only CloudFront to make requests to the bucket"
}
