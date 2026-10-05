output "aws_region" {
  description = "AWS region the resources are deployed into"
  value       = var.aws_region
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for synthetic data artifacts"
  value       = aws_s3_bucket.synth_data.bucket
}

output "redshift_cluster_id" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.this.cluster_identifier
}

output "redshift_endpoint" {
  description = "Redshift cluster endpoint (host:port)"
  value       = "${aws_redshift_cluster.this.dns_name}:${aws_redshift_cluster.this.port}"
}

output "redshift_database_name" {
  description = "Redshift database name"
  value       = aws_redshift_cluster.this.database_name
}

output "redshift_password_parameter" {
  description = "SSM parameter holding the master password: aws ssm get-parameter --name <this> --with-decryption"
  value       = aws_ssm_parameter.redshift_master_password.name
}

output "ecs_cluster_name" {
  description = "ECS cluster running the Fargate tasks"
  value       = aws_ecs_cluster.this.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the Fargate task definition"
  value       = aws_ecs_task_definition.python.arn
}

output "fargate_security_group_id" {
  description = "Security group to use when running Fargate tasks"
  value       = aws_security_group.fargate.id
}

output "ecs_log_group" {
  description = "CloudWatch Logs group for task output"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "ecr_repo_url" {
  description = "ECR repository for the app image (docker push here)"
  value       = aws_ecr_repository.app.repository_url
}

output "run_task_command" {
  description = "Ready-to-use command to launch the Python task on Fargate"
  value       = <<-EOT
    aws ecs run-task \
      --cluster ${aws_ecs_cluster.this.name} \
      --task-definition ${aws_ecs_task_definition.python.arn} \
      --launch-type FARGATE \
      --network-configuration "awsvpcConfiguration={subnets=[${join(",", aws_subnet.public[*].id)}],securityGroups=[${aws_security_group.fargate.id}],assignPublicIp=ENABLED}"
  EOT
}
