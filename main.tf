terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

data "aws_caller_identity" "current" {}

# Auto-detect this PC's public IP (overridable via var.my_ip)
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  name_prefix = coalesce(var.project_name, "synth-data-demo")

  # Public IP of this machine, used to allow direct Redshift access
  my_ip = coalesce(var.my_ip, chomp(data.http.my_ip.response_body))

  tags = {
    Project     = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
