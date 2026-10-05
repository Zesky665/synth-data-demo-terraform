# S3 bucket to hold synthetic data artifacts
resource "aws_s3_bucket" "synth_data" {
  bucket = "${local.name_prefix}-${var.environment}-data"

  # Demo only: allows tearing down a non-empty bucket
  force_destroy = true
}
