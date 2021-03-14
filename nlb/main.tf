# How often to check the liveliness of the container
variable "health_check_interval" {
  default = "30"
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
variable "deregistration_delay" {
  default = "30"
}

resource "aws_lb" "main" {
  name                             = "${var.name}-tg-${var.environment}"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  # launch lbs in public or private subnets based on "internal" variable
  internal = false
  subnets  = var.subnets
}

# adds a tcp listener to the load balancer and allows ingress
resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.main.id
  port              = 1025
  protocol          = var.lb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "main" {
  depends_on           = [aws_lb.main]
  name                 = "${var.name}-${var.environment}"
  port                 = 1025
  protocol             = var.lb_protocol
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    protocol            = var.lb_protocol
    interval            = var.health_check_interval
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}


output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.main.arn
}
