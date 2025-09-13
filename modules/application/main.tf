locals {
  full_domain = "${var.subdomain}.${var.domain_name}"
}

# ===================================
# Security Groups
# ===================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
    Type = "Security Group"
    Tier = "Web"
  })
}

# Web Tier Security Group
resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Security group for Web tier EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-web-sg"
    Type = "Security Group"
    Tier = "Application"
  })
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "MySQL from Web tier"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
    Type = "Security Group"
    Tier = "Database"
  })
}

# ===================================
# Application Load Balancer
# ===================================

resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
    Type = "Application Load Balancer"
    Tier = "Web"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${var.name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health.html"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.name}-web-tg"
    Type = "Target Group"
    Tier = "Web"
  })
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
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

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ===================================
# IAM Role for EC2 instances
# ===================================

resource "aws_iam_role" "web" {
  name = "${var.name}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-web-role"
    Type = "IAM Role"
    Tier = "Application"
  })
}

resource "aws_iam_role_policy_attachment" "web_ssm_policy" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "web_policy" {
  name = "${var.name}-web-policy"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.name}-web-profile"
  role = aws_iam_role.web.name
}

# ===================================
# User Data Script
# ===================================

locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host                    = aws_db_instance.main.endpoint
    db_name                    = var.db_name
    db_username                = var.db_username
    secrets_manager_secret_name = aws_secretsmanager_secret.db_password.name
    aws_region                 = data.aws_region.current.name
    domain                     = local.full_domain
  }))
}

data "aws_region" "current" {}

# ===================================
# Launch Template and Auto Scaling Group
# ===================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name}-web-instance"
      Type = "EC2 Instance"
      Tier = "Application"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name}-web-lt"
    Type = "Launch Template"
    Tier = "Application"
  })
}

resource "aws_autoscaling_group" "web" {
  name                      = "${var.name}-web-asg"
  vpc_zone_identifier       = var.private_app_subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.web_min_capacity
  max_size         = var.web_max_capacity
  desired_capacity = var.web_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-web-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ===================================
# Secrets Manager for Database Password
# ===================================

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.name}-db-password"
  description = "RDS database master password"
  
  tags = merge(var.tags, {
    Name = "${var.name}-db-password"
    Type = "Secrets Manager Secret"
    Tier = "Database"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# ===================================
# RDS Database
# ===================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
    Type = "DB Subnet Group"
    Tier = "Database"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${var.name}-database"

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name}-database"
    Type = "RDS Instance"
    Tier = "Database"
  })
}

