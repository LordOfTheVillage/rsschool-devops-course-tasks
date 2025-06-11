output "aws_region" {
  value = var.aws_region
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}

output "github_actions_role_name" {
  value = aws_iam_role.github_actions_role.name
}

output "github_actions_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}

output "environment" {
  value = var.environment
}