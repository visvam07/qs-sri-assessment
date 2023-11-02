##################################################################
# ECR REPO URI
##################################################################
output "ecr_image_uri" {
  description = "ECR Repository image URI"
    value = "${module.ecr.repository_url}:latest"
}
##################################################################
# Roles for ECS tasks
##################################################################
output "task_iam_role_arn" {
  description = "Task Role ARN"
  value       = module.ecs_service.tasks_iam_role_arn
}

output "task_exec_iam_role_arn" {
  description = "Task Execution Role ARN"
  value       = module.ecs_service.task_exec_iam_role_arn
}
##################################################################
# ALB DNS NAME
##################################################################
output "alb_dns_name" {
  description = "ALB DNS Name"
  value = module.alb.lb_dns_name
}
