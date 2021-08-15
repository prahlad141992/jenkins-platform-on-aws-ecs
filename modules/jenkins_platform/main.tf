data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" selected {
  id = var.vpc_id
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

// EFS security group
resource "aws_security_group" efs_security_group {
  name        = "${var.name_prefix}-efs"
  description = "${var.name_prefix} efs security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller_security_group.id]
    from_port       = 2049
    to_port         = 2049
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Jenkins security group
resource "aws_security_group" jenkins_controller_security_group {
  name        = "${var.name_prefix}-controller"
  description = "${var.name_prefix} controller security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = var.alb_create_security_group ? [aws_security_group.alb_security_group[0].id] : var.alb_security_group_ids
    from_port       = var.jenkins_controller_port
    to_port         = var.jenkins_controller_port
    description     = "Communication channel to jenkins leader"
  }

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = var.alb_create_security_group ? [aws_security_group.alb_security_group[0].id] : var.alb_security_group_ids
    from_port       = var.jenkins_jnlp_port
    to_port         = var.jenkins_jnlp_port
    description     = "Communication channel to jenkins leader"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


// ALB
resource "aws_security_group" alb_security_group {
  count = var.alb_create_security_group ? 1 : 0

  name        = "${var.name_prefix}-alb"
  description = "${var.name_prefix} alb security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTP Public access"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTPS Public access"
  }

    ingress {
    protocol        = "tcp"
    from_port       = 50000
    to_port         = 50000
    cidr_blocks     = var.alb_ingress_allow_cidrs
    description     = "Communication channel to jenkins leader"
    }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// ELB Load balancer

resource "aws_elb" "elb" {
  name               = replace("${var.name_prefix}-ELB", "_", "-")
  internal           = var.alb_type_internal
  security_groups    = var.alb_create_security_group ? [aws_security_group.alb_security_group[0].id] : var.alb_security_group_ids
  subnets            = var.alb_subnet_ids

  lifecycle {
    create_before_destroy = true
  }

    listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.alb_acm_certificate_arn
  }

  listener {
    instance_port     = 50000
    instance_protocol = "tcp"
    lb_port           = 50000
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:8080/login"
    interval            = 300
  }

  #instances                   = [aws_instance.foo.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 60

  tags = var.tags
}