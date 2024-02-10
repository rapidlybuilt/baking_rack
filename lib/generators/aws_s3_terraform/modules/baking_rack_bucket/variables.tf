variable "bucket_name" {
  description = "The name of the bucket without the www. prefix. Normally domain_name."
}

variable "domain_name" {
  description = "The domain name for the website for the CORS policy."
}

variable "common_tags" {
  description = "Common tags you want applied to all components."
  default     = {}
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
