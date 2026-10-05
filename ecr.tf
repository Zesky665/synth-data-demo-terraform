# ---------------------------------------------------------------------------
# ECR: container image for the Fargate task
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  # Demo only: allow destroying a repo that still contains images
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

locals {
  app_image = "${aws_ecr_repository.app.repository_url}:${var.container_tag}"
}

# Let this PC build-and-push (docker push) to the repo.
# Inline policy: the user is already at the managed PoliciesPerUser quota (10).
resource "aws_iam_user_policy" "local_ecr_push" {
  name = "ecr-push-synth-data-demo-dev"
  user = data.aws_iam_user.local.user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid      = "RepoPushPull"
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = [aws_ecr_repository.app.arn]
      },
    ]
  })
}
