resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.main.website_endpoint
    origin_id   = "S3-${var.bucket_name}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = concat([var.from_domain_name], var.subject_alternative_names)
  comment = "Redirects to ${var.to_domain_name}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }

      headers = ["Origin"]
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.ssl_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  tags = local.tags
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  redirect_all_requests_to {
    protocol  = "https"
    host_name = var.to_domain_name
  }
}

module "ssl_certificate" {
  source                            = "cloudposse/acm-request-certificate/aws"
  version                           = "0.18.0"
  domain_name                       = var.from_domain_name
  subject_alternative_names         = var.subject_alternative_names
  process_domain_validation_options = true
  ttl                               = "300"
  zone_id                           = var.zone_id
  environment                       = "us-east-1" # required for CloudFront

  tags = local.tags
}

resource "aws_route53_record" "main-a" {
  zone_id = var.zone_id
  name    = var.from_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sans-a" {
  for_each = toset(var.subject_alternative_names)

  zone_id = var.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
