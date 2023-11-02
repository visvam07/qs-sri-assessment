##################################################################
# Outputs for GitHub Secrets
##################################################################
output "github_actions_access_key" {
  value     = aws_iam_access_key.github_actions.id
  sensitive = true
}

output "github_actions_secret_key" {
  value     = aws_iam_access_key.github_actions.secret
  sensitive = true
}