##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_subnet_ids" "public_euw1" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*public*"
  }
}

data "aws_subnet" "public_euw1" {
  for_each = toset(data.aws_subnet_ids.public_euw1.ids)

  id = each.key
}

locals {
  availability_zone_subnets_public_euw1 = {
    for s in data.aws_subnet.public_euw1 : s.availability_zone => s.id...
  }
}

locals {
  public_subnet_euw1_ids_string = join(",", [for subnet_ids in local.availability_zone_subnets_public_euw1 : sort(subnet_ids)[0]])
  public_subnet_euw1_ids_list   = split(",", local.public_subnet_euw1_ids_string)
}

data "aws_subnet_ids" "private_euw1" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*private*"
  }
}

data "aws_subnet" "private_euw1" {
  for_each = toset(data.aws_subnet_ids.private_euw1.ids)

  id = each.key
}

locals {
  availability_zone_subnets_private_euw1 = {
    for s in data.aws_subnet.private_euw1 : s.availability_zone => s.id...
  }
}

locals {
  private_subnet_euw1_ids_string = join(",", [for subnet_ids in local.availability_zone_subnets_private_euw1 : sort(subnet_ids)[0]])
  private_subnet_euw1_ids_list   = split(",", local.private_subnet_euw1_ids_string)
}

output "subnet-priv-ids" {
  value = local.private_subnet_euw1_ids_list
}

output "subnet-pub-ids" {
  value = local.public_subnet_euw1_ids_list
}

module "security_groups" {
  source         = "./security-groups"
  name           = var.name
  vpc_id         = var.vpc_id
  environment    = var.environment
  container_port = var.container_port
}

module "nlb" {
  source              = "./nlb"
  name                = var.name
  vpc_id              = var.vpc_id
  subnets             = local.public_subnet_euw1_ids_list
  environment         = var.environment
  nlb_security_groups = [module.security_groups.nlb]
  lb_protocol         = var.lb_protocol
}

module "ecs" {
  source                      = "./ecs"
  name                        = var.name
  vpc_id                      = var.vpc_id
  environment                 = var.environment
  region                      = var.aws-region
  subnets                     = local.private_subnet_euw1_ids_list
  aws_lb_target_group_arn     = module.nlb.aws_lb_target_group_arn
  ecs_service_security_groups = [module.security_groups.ecs_tasks]
  container_port              = var.container_port
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  service_desired_count       = var.service_desired_count
  container_image             = var.container_image
  container_environment = [
    { name = "LOG_LEVEL",
    value = "DEBUG" },
    { name = "PORT",
    value = var.container_port }
  ]
}
