variable "name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "subnets" {
  description = "Comma separated list of subnet IDs"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "nlb_security_groups" {
  description = "Comma separated list of security groups"
}

variable "lb_protocol" {
  description = "load_balancer protocol "
}
