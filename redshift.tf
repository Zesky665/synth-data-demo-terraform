# ---------------------------------------------------------------------------
# Redshift cluster
# ---------------------------------------------------------------------------

# Master password: generated once, stored as a SecureString for ECS + humans
resource "random_password" "redshift_master" {
  length  = 24
  special = false # keeps connection strings quoting-friendly
}

resource "aws_ssm_parameter" "redshift_master_password" {
  name        = "/${local.name_prefix}/${var.environment}/redshift-master-password"
  description = "Redshift master password (managed by Terraform)"
  type        = "SecureString"
  value       = random_password.redshift_master.result
}

resource "aws_redshift_subnet_group" "this" {
  name       = "${local.name_prefix}-${var.environment}"
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_security_group" "redshift" {
  name        = "${local.name_prefix}-${var.environment}-redshift"
  description = "Redshift: allow 5439 from Fargate tasks and the local PC"
  vpc_id      = aws_vpc.main.id

  # Fargate tasks
  ingress {
    description     = "PostgreSQL from Fargate tasks"
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate.id]
  }

  # This PC
  ingress {
    description = "PostgreSQL from the local machine"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_redshift_cluster" "this" {
  cluster_identifier = "${local.name_prefix}-${var.environment}"
  database_name      = var.redshift_database_name
  master_username    = var.redshift_master_username
  master_password    = random_password.redshift_master.result

  node_type       = var.redshift_node_type
  cluster_type    = "single-node"
  number_of_nodes = 1

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  # Lets COPY read seed CSVs from S3 (see redshift_iam.tf)
  iam_roles = [aws_iam_role.redshift_s3.arn]

  # Demo: reachable from this PC over the internet (SG still restricts source IP)
  publicly_accessible = true

  # Demo: make teardown fast. ra3 requires 1-35 day snapshot retention.
  skip_final_snapshot                 = true
  automated_snapshot_retention_period = 1
  apply_immediately                   = true
}
