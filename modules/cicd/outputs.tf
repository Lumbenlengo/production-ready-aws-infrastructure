# modules/cicd/outputs.tf

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.app.arn
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.app.name
}

output "codepipeline_id" {
  description = "CodePipeline ID"
  value       = aws_codepipeline.pipeline.id
}

output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.pipeline.arn
}

output "github_connection_arn" {
  description = "CodeStar GitHub connection ARN — must be manually authorised in the AWS Console after first apply"
  value       = aws_codestarconnections_connection.github.arn
}
