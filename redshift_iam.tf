# ---------------------------------------------------------------------------
# IAM role attached to the Redshift cluster so COPY can read from S3
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "redshift_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "redshift_s3" {
  name               = "${local.name_prefix}-${var.environment}-redshift-s3"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume.json
}

resource "aws_iam_role_policy" "redshift_s3_read" {
  name = "read-seed-data"
  role = aws_iam_role.redshift_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.synth_data.arn]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.synth_data.arn}/${var.seed_s3_prefix}/*",
        ]
      },
    ]
  })
}
