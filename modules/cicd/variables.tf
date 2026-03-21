# modules/cicd/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "github_owner" {
  description = "GitHub username or organisation"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_repo_url" {
  description = "Full GitHub repository URL"
  type        = string
}

variable "artifact_bucket_id" {
  description = "S3 artifact bucket name (used as artifact store location)"
  type        = string
}

variable "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN (used in IAM policies — must be a valid ARN)"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name for CodeDeploy"
  type        = string
}

variable "target_group_name" {
  description = "ALB target group name for CodeDeploy load balancer info"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for pipeline approval notifications"
  type        = string
  default     = ""
}

variable "rollback_alarm_names" {
  description = "List of CloudWatch alarm names that trigger automatic CodeDeploy rollback"
  type        = list(string)
  default     = []
}
