 # 1. The Application Load Balancer (The "Receptionist")
# This is the public entry point for all your web traffic.
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. The Target Group (The "Kitchen")
# This defines where the traffic should go (your EC2 instances) 
# and how to check if they are healthy.
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"    # ALB will ping your server's root
    interval            = 30     # Check every 30 seconds
    timeout             = 5      # Wait 5 seconds for a response
    healthy_threshold   = 3      # 3 success = "Healthy"
    unhealthy_threshold = 2      # 2 failures = "Unhealthy"
  }
}

# 3. The Listener (The "Ear")
# This tells the ALB to listen on port 80 and forward 
# everything to the Target Group defined above.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}