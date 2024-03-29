module "baking_rack" {
  source = "./modules/baking_rack"

  bucket_name       = "${module.label.id}-www"
  domain_name       = var.domain_name
  github_repository = var.github_repository
  branch_name       = var.github_branch_name

  tags = merge(
    module.label.tags,
    {
      Application = "baking_rack"
    }
  )
}

output "baking_rack_iam_role_arn" {
  value = module.baking_rack.iam_role_arn
}

output "baking_rack_bucket_name" {
  value = module.baking_rack.bucket_name
}
