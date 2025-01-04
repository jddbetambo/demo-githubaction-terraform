# ALB
resource "aws_lb" "alb" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = var.subnets
  drop_invalid_header_fields = true # Checkov
  enable_deletion_protection = true # Checkov
  
  # Checkov
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }

}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08" # Checkov
  certificate_arn = "arn:aws:acm-pca:us-east-1:445567107707:certificate-authority/ccb55f9c-82d3-4115-a347-4a9df3db4f6a" # Checkov

  default_action {
    type             = "forward"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

    target_group_arn = aws_lb_target_group.tg.arn
  }
  
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  # Checkov
  health_check {
    path                = "/health"  # Adjust this path as needed
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "tga" {
  count = length(var.instances)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.instances[count.index]
  port             = 80
}


/* resource "aws_wafregional_web_acl_association" "foo" {
  resource_arn = aws_lb.alb.arn
  web_acl_id = aws_wafregional_web_acl.foo.id
} */

# Step 1: Create the S3 Bucket
resource "aws_s3_bucket" "lb_logs" {
  bucket = "lb_logs_jdd"  # Replace with a unique bucket name
  //acl    = "private"                   # Set the ACL to private

  tags = {
    Name        = "lb_logs_jdd"
    Environment = "Dev"
  }
}

# Step 2: Create a Bucket Policy for Read and Write Access
resource "aws_s3_bucket_policy" "example_policy" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource  = [
          "${aws_s3_bucket.lb_logs.arn}/*",  # Object-level permissions
           aws_s3_bucket.lb_logs.arn           # Bucket-level permissions
        ]
      }
    ]
  })
}
