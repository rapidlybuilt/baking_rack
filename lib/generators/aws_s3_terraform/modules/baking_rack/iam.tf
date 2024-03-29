# Allow GitHub Actions to upload files to the S3 Bucket
# https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/

resource "aws_iam_openid_connect_provider" "github_openid_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # AWS says this is deprecated for githubusercontent.com
  thumbprint_list = ["3ea80e902fc385f36bc08193fbc678202d572994"]
}

resource "aws_iam_role" "s3_bucket_uploader" {
  name               = "${var.bucket_name}-uploader"
  assume_role_policy = data.aws_iam_policy_document.s3_bucket_uploader_assumed_role.json
  tags = local.tags
}

resource "aws_iam_policy" "s3_bucket_uploader_policy" {
  name   = "${var.bucket_name}-uploader"
  policy = data.aws_iam_policy_document.s3_bucket_uploader_policy.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "s3_bucket_uploader_policy_attachment" {
  role       = aws_iam_role.s3_bucket_uploader.name
  policy_arn = aws_iam_policy.s3_bucket_uploader_policy.arn
}

data "aws_iam_policy_document" "s3_bucket_uploader_assumed_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_openid_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_repository}:ref:refs/heads/${var.branch_name}",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_bucket_uploader_policy" {
  statement {
    sid       = "BucketActions"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }

  statement {
    sid = "FileActions"
    actions = [
      "s3:GetObject", "s3:GetObjectAcl",
      "s3:PutObject", "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        "${base64sha512("REFER-SECRET-19265125-${var.bucket_name}-52865926")}",
      ]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
