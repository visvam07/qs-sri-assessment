provider "aws" {
  region = local.region
  profile = local.profile
}

locals {
  region = "eu-west-2"
  profile = "srirao-personal"
  name   = "qs-${basename(path.cwd)}"

  tags = {
    Name       = local.name
  }
}
##################################################################
# IAM User for GitHub Actions
##################################################################
resource "aws_iam_user" "github_actions" {
  name = "github_actions_user"
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

resource "aws_iam_user_policy" "github_actions_policy" {
  name = "github_actions_policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "iam:PassRole"
        ],
        Resource = "*",
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService": "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*" # Ideally, restrict this to the specific ECR repository ARN
      }
    ]
  })
}