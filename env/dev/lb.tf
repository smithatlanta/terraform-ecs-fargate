# note that this creates the alb, target group, and access logs
# the listeners are defined in lb-http.tf and lb-https.tf
# delete either of these if your app doesn't need them
# but you need at least one

# Whether the application is available on the public internet,
# also will determine which subnets will be used (public or private)
variable "internal" {
  default = true
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
variable "deregistration_delay" {
  default = "30"
}

# The path to the health check for the load balancer to know if the container(s) are ready
variable "health_check" {
}

# How often to check the liveliness of the container
variable "health_check_interval" {
  default = "30"
}

# How long to wait for the response on the health check path
variable "health_check_timeout" {
  default = "10"
}

# What HTTP response code to listen for
variable "health_check_matcher" {
  default = "200"
}

variable "lb_access_logs_expiration_days" {
  default = "3"
}

resource "aws_alb" "main" {
  name = "${var.app}-${var.environment}"

  # launch lbs in public or private subnets based on "internal" variable
  internal = var.internal
  subnets = split(
    ",",
    var.internal == true ? var.private_subnets : var.public_subnets,
  )
  security_groups = [aws_security_group.nsg_lb.id]
  tags            = var.tags

  # enable access logs in order to get support from aws
  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.lb_access_logs.bucket
  }
}

resource "aws_alb_target_group" "main" {
  name                 = "${var.app}-${var.environment}"
  port                 = var.lb_port
  protocol             = var.lb_protocol
  vpc_id               = var.vpc
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  tags = var.tags
}

data "aws_elb_service_account" "main" {
}

# The load balancer DNS name
output "lb_dns" {
  value = aws_alb.main.dns_name
}
