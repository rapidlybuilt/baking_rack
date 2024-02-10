variable "aws_region" {
  type        = string
  description = "AWS region for regional resources."
}

variable "zone_id" {
  type        = string
  description = "AWS Route53 Zone ID hosting the domain name."
}

variable "domain_name" {
  type        = string
  description = "The domain name for the website."
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket without the www. prefix. Normally domain_name."
}

variable "github_repository" {
  description = "The GitHub organization or username slash the repository name. i.e. organization/repository"
}

variable "github_branch_name" {
  description = "The branch name inside the GitHub repository."
}

variable "common_tags" {
  description = "Common tags you want applied to all components."
  default     = {}
}

locals {
  secret_handshake = base64sha512("REFER-SECRET-19265125-${var.bucket_name}-52865926")
}
