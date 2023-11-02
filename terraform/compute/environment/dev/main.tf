provider "aws" {
  region = local.region
  profile = local.profile
}

data "aws_availability_zones" "available" {}

locals {
  region = "eu-west-2"
  profile = "srirao-personal"
  name   = "qs-${basename(path.cwd)}"

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  container_name = "assessment"
  container_port = 3000
  cpu    = 512
  memory = 1024

  repository_name = "assessment"

  tags = {
    Name       = local.name
  }
}

##################################################################
# Cluster
##################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = local.name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 0
        base   = 0
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 50
      }
    }
  }

  tags = local.tags
}

##################################################################
# Service
##################################################################

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.cluster_arn

  cpu    = local.cpu
  memory = local.memory
  launch_type     = "FARGATE"
  desired_count = 2
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 100

  # Container definition(s)
  container_definitions = {

    (local.container_name) = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "busybox:latest"  # Placeholder image
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      readonly_root_filesystem = false
      enable_cloudwatch_logging = true
      memory_reservation = 100
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.alb.target_group_arns, 0)
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb_sg.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}

##################################################################
# Supporting Resources
##################################################################

resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-${local.container_name}"
      backend_protocol = "HTTP"
      backend_port     = local.container_port
      target_type      = "ip"
    },
  ]

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

##################################################################
# ECR
##################################################################

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${local.name}-${local.repository_name}"
  repository_image_tag_mutability = "MUTABLE"  # This allows overwriting image tags
  repository_force_delete = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
  }
}