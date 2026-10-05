# ---------------------------------------------------------------------------
# ECS Fargate: serverless compute for the Python script
# ---------------------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}-${var.environment}"
  retention_in_days = 7
}

# Tasks in this SG can reach Redshift (see redshift.tf ingress rule)
resource "aws_security_group" "fargate" {
  name        = "${local.name_prefix}-${var.environment}-fargate"
  description = "Fargate tasks: outbound only"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Role the ECS agent uses: pull image, write logs, inject SSM secrets
resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-${var.environment}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the execution role to read the Redshift password SecureString
resource "aws_iam_role_policy" "task_execution_ssm" {
  name = "read-redshift-password"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = [aws_ssm_parameter.redshift_master_password.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = ["*"] # covers the account default aws/ssm key
      },
    ]
  })
}

# Role the Python script runs as: Redshift + S3 access
resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-${var.environment}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_ecs_task_definition" "python" {
  family                   = "${local.name_prefix}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  # Matches the ARM64 image built on Apple Silicon
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "python-script"
      image     = coalesce(var.container_image, local.app_image)
      command   = var.container_command
      essential = true

      environment = [
        { name = "DB_HOST", value = aws_redshift_cluster.this.dns_name },
        { name = "DB_PORT", value = "5439" },
        { name = "DB_NAME", value = var.redshift_database_name },
        { name = "DB_USER", value = var.redshift_master_username },
        { name = "S3_BUCKET", value = aws_s3_bucket.synth_data.bucket },
        { name = "S3_PREFIX", value = "synthetic" },
        { name = "MODEL_MODE", value = var.model_mode },
        { name = "SCALE", value = format("%g", var.sample_scale) },
        { name = "AWS_REGION", value = var.aws_region },
      ]

      # Injected at start from SSM Parameter Store
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.redshift_master_password.arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "script"
        }
      }
    }
  ])
}
