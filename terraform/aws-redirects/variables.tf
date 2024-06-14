variable "from_domain_name" {
  description = "The domain name of inbound requests"
}

variable "to_domain_name" {
  description = "The domain name requests should be redirected to."
}

variable "bucket_name" {
  description = "The S3 bucket name containing the redirect rule"
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "The zone id of the Route53 Hosted Zone which can be used instead of var.zone_name."
  type        = string
}

variable "tags" {
  description = "Tags you want applied to all components."
  default     = {}
}

locals {
  application_tag = "baking_rack_redirects"

  tags = merge(
    {
      Application   = local.application_tag,
      ApplicationId = var.bucket_name
    },
    var.tags
  )
}
