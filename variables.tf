variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used as a prefix for created resources"
  type        = string
  default     = "synth-data-demo"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "my_ip" {
  description = "Public IP of this PC, allowed to reach Redshift directly. Auto-detected when null."
  type        = string
  default     = null
}

variable "local_iam_username" {
  description = "IAM user on this PC that gets Redshift access"
  type        = string
  default     = "terraform"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

# --- Redshift --------------------------------------------------------------

variable "redshift_database_name" {
  description = "Name of the Redshift database"
  type        = string
  default     = "synthdata"
}

variable "redshift_master_username" {
  description = "Redshift master user name"
  type        = string
  default     = "admin"
}

variable "redshift_node_type" {
  description = "Redshift node type (single node). DC2 types are deprecated; ra3.large is the cheapest single-node option."
  type        = string
  default     = "ra3.large"
}

# --- Fargate ---------------------------------------------------------------

variable "container_image" {
  description = "Container image the Fargate task runs. Defaults to the app ECR repo image."
  type        = string
  default     = null
}

variable "container_tag" {
  description = "Tag of the app image in ECR"
  type        = string
  default     = "latest"
}

variable "container_command" {
  description = "Command the Fargate task container runs (override to run something else)"
  type        = list(string)
  default     = ["python", "scripts/synthesize_titanic_redshift.py"]
}

variable "fargate_cpu" {
  description = "Task vCPU (SDV fitting needs more than the 256 minimum)"
  type        = number
  default     = 1024
}

variable "fargate_memory" {
  description = "Task memory (MiB)"
  type        = number
  default     = 2048
}

variable "seed_s3_prefix" {
  description = "S3 prefix holding the seed CSVs Redshift COPYs from"
  type        = string
  default     = "redshift-seed"
}

variable "model_mode" {
  description = "Script behaviour: fit = train a new HMA model and save to S3; load = reuse the saved model"
  type        = string
  default     = "fit"

  validation {
    condition     = contains(["fit", "load"], var.model_mode)
    error_message = "model_mode must be 'fit' or 'load'."
  }
}

variable "sample_scale" {
  description = "Sampling scale relative to the original dataset size"
  type        = number
  default     = 1.0
}
