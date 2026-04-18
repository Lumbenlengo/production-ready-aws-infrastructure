# modules/loadbalancer/main.tf

# ── ALB Security Group ────────────────────────────────────────────────
# Defines who can access the Load Balancer (Public Internet)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Allow HTTP and HTTPS inbound to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# ── Application Load Balancer (ALB) ───────────────────────────────────
# Public-facing entry point distributed across public subnets
resource "aws_lb" "main" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# ── Target Group ──────────────────────────────────────────────────────
# Routes traffic to EC2 instances on port 8000
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # ZERO DOWNTIME: Wait 60 seconds for active connections to drain 
  # before terminating an old instance during a deployment.
  deregistration_delay = 60

  health_check {
    enabled             = true
    path                = "/" # Root path where the Snake app responds
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2   # Consecutive successes to mark as Healthy
    unhealthy_threshold = 2   # Consecutive failures to mark as Unhealthy
    timeout             = 5   # Seconds to wait for a response
    interval            = 15  # Seconds between health check attempts
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
  }
}

# ── HTTP Listener (Redirect to HTTPS) ─────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ── HTTPS Listener (Secure Traffic) ───────────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ── ACM Certificate ───────────────────────────────────────────────────
# Managed via DNS validation. Ensure CNAME is present in your DNS provider.
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${var.project_name}-cert"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Validates the certificate is issued before the listener uses it
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}

# ── Route53 Alias Record ──────────────────────────────────────────────
# Points your domain directly to the ALB DNS name
resource "aws_route53_record" "alb" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}