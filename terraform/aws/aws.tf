data "aws_caller_identity" "current" {}

data "aws_arn" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}
