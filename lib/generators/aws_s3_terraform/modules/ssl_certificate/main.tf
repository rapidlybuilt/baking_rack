provider "aws" {
  region = var.aws_region
  alias  = "acm_provider"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the website."
}

variable "zone_id" {
  type        = string
  description = "AWS Route53 Zone ID hosting the domain name."
}

variable "aws_region" {
  type        = string
  description = "AWS region for regional resources."
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags you want applied to all components."
  default     = {}
}

resource "aws_acm_certificate" "ssl_certificate" {
  provider          = aws.acm_provider
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = var.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

output "ssl_certificate_arn" {
  value       = aws_acm_certificate_validation.cert_validation.certificate_arn
  description = "AWS ACM certificate resource's ARN"
}
