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
  default     = "main"
}

variable "tags" {
  description = "Tags you want applied to all components."
  default     = {}
}

locals {
  application_tag = "baking_rack"

  # Keep S3 from responding to direct requests (force requests through CloudFront instead)
  handshake = base64sha512("REFER-HANDSHAKE-${var.bucket_name}-52865926")

  tags = merge(
    {
      Application = local.application_tag,
      ApplicationId = var.bucket_name
    },
    var.tags
  )
}
