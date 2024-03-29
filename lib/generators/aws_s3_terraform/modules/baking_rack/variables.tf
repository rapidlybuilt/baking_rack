variable "bucket_name" {
  description = "The name of the bucket without the www. prefix. Normally domain_name."
}

variable "domain_name" {
  description = "The domain name for the website for the CORS policy."
}

variable "github_repository" {
  description = "The GitHub organization or username slash the repository name. i.e. organization/repository"
}

variable "branch_name" {
  description = "The branch name inside the GitHub repository."
}

variable "secret_handshake" {
  description = "A secret string to prevent direct access to S3 objects."
}

variable "tags" {
  description = "Tags you want applied to all components."
  default     = {}
}

locals {
  application_tag = "baking_rack"

  # Keep S3 from responding to direct requests (force requests through CloudFront instead)
  secret_handshake = base64sha512("REFER-SECRET-19265125-${var.bucket_name}-52865926")

  tags = merge(
    var.tags,
    {
      Application = local.application_tag
    }
  )
}
