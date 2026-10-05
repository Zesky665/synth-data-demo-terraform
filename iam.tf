# ---------------------------------------------------------------------------
# IAM: Fargate task -> Redshift/S3, and this PC -> Redshift
# ---------------------------------------------------------------------------

# What the Python script can do inside AWS
resource "aws_iam_role_policy" "task_access" {
  name = "task-redshift-s3-access"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RedshiftDataApi"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:BatchExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:CancelStatement",
          "redshift-data:ListStatements",
          "redshift-data:ListDatabases",
          "redshift-data:ListSchemas",
          "redshift-data:ListTables",
          "redshift-data:DescribeTable",
        ]
        # redshift-data actions don't support resource-level scoping
        Resource = "*"
      },
      {
        Sid    = "RedshiftTempCredentials"
        Effect = "Allow"
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters",
        ]
        Resource = "*"
      },
      {
        Sid    = "SynthDataBucket"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.synth_data.arn,
          "${aws_s3_bucket.synth_data.arn}/*",
        ]
      },
    ]
  })
}

# Allow this PC (the local IAM user) to use Redshift
resource "aws_iam_policy" "local_redshift_access" {
  name        = "${local.name_prefix}-${var.environment}-local-redshift"
  description = "Allows the local workstation to query Redshift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RedshiftDataApi"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:BatchExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:CancelStatement",
          "redshift-data:ListStatements",
          "redshift-data:ListDatabases",
          "redshift-data:ListSchemas",
          "redshift-data:ListTables",
          "redshift-data:DescribeTable",
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters",
        ]
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_user" "local" {
  user_name = var.local_iam_username
}

resource "aws_iam_user_policy_attachment" "local_redshift" {
  user       = data.aws_iam_user.local.user_name
  policy_arn = aws_iam_policy.local_redshift_access.arn
}
