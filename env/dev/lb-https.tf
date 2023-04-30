# adds an https listener to the load balancer
# (delete this file if you only want http)

# The port to listen on for HTTPS, always use 443

resource "aws_alb_listener" "app_https_app" {
  load_balancer_arn = aws_alb.main.id
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.app_cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.id
  }
}

resource "aws_security_group_rule" "app_ingress_lb_https_app" {
  type              = "ingress"
  description       = "HTTPS"
  from_port         = var.https_port
  to_port           = var.https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nsg_lb.id
}

//cert matches cname
resource "aws_acm_certificate" "app_cert" {
  domain_name       = local.subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "app_cert" {
  certificate_arn = aws_acm_certificate.app_cert.arn
}

resource "aws_lb_listener_certificate" "app_cert" {
  listener_arn    = aws_alb_listener.app_https_app.arn
  certificate_arn = aws_acm_certificate.app_cert.arn
}

