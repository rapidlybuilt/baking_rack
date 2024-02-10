terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform.topdan.com"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
