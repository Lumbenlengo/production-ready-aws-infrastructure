output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.app.arn
}

output "pipeline_name" {
  value = aws_codepipeline.pipeline.name
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.app.name
}
