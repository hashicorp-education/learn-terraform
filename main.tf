# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

data "aws_ami" "claire" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "claire" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}

resource "aws_ecr_repository" "claire" {
  name                 = "cabine-repo"
  image_tag_mutability = "MUTABLE"
  
  encryption_configuration {
  
    encryption_type = "AES256"

  }
}

#create a bucket
resource "aws_s3_bucket" "claire" {
  bucket = "claire-bucket"

  tags = {
    Name        = "claire-bucket"
    Environment = "Dev"
  }
}

resource "aws_lb" "claire" {
  name               = "claire-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]

  tags = {
    Name = "claire-alb"
  }
}

resource "aws_lb_target_group" "claire" {
  name     = "claire-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.claire.id

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "claire-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.claire.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.claire.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.example.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.claire.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_sg"
  }
}

resource "aws_acm_certificate" "claire" {
  domain_name               = "example.com"
  validation_method         = "DNS"
  subject_alternative_names = ["www.example.com"]

  tags = {
    Name = "claire-certificate"
  }
}

# database instance creation
resource "aws_db_instance" "claire" {
  allocated_storage    = 20
  db_name              = var.db_name
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.username
  password             = "3g_yI81udju#cc|pqep"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false

  tags = {
      Name = "claire-db"
   }
}

resource "aws_db_proxy" "claire" {
  name                      = "claire-proxy"
  engine_family             = "MYSQL"
  role_arn                  = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids            = [aws_subnet.claire1.id, aws_subnet.claire2.id]
  require_tls               = true

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.rds_auth.arn
  }

  tags = {
    Name = "claire-db-proxy"
  }
}

resource "aws_secretsmanager_secret" "rds_auth" {
  name = "rds-auth"
}

resource "aws_iam_role" "rds_proxy" {
  name = "rds-proxy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSProxyReadOnlyAccess"
}

