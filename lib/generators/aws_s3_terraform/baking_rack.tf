module "baking_rack_bucket" {
  source = "./modules/baking_rack_bucket"

  bucket_name       = var.bucket_name
  domain_name       = var.domain_name
  github_repository = var.github_repository
  branch_name       = var.github_branch_name
  secret_handshake  = local.secret_handshake
}

output "baking_rack_iam_role_arn" {
  value = module.baking_rack_bucket.iam_role_arn
}

output "baking_rack_bucket_name" {
  value = module.baking_rack_bucket.bucket_name
}
