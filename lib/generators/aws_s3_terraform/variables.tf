variable "domain_name" {
  type        = string
  description = "The domain name for the website."
}

variable "github_repository" {
  description = "The GitHub organization or username slash the repository name. i.e. organization/repository"
}

variable "github_branch_name" {
  description = "The branch name inside the GitHub repository."
}
