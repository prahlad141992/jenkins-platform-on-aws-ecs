// Jenkins Container Infra
resource "aws_ecs_cluster" jenkins_controller {
  name               = "${var.name_prefix}-main"
  capacity_providers = ["FARGATE"]
  tags               = var.tags
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster" jenkins_agents {
  name               = "${var.name_prefix}-spot"
  capacity_providers = ["FARGATE_SPOT"]
  tags               = var.tags
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

data "template_file" jenkins_controller_container_def {
  template = file("${path.module}/templates/jenkins-controller.json.tpl")

  vars = {
    name                = "${var.name_prefix}-controller"
    jenkins_controller_port = var.jenkins_controller_port
    jnlp_port           = var.jenkins_jnlp_port
    source_volume       = "${var.name_prefix}-efs"
    jenkins_home        = "/var/jenkins_home"
    container_image     = aws_ecr_repository.jenkins_controller.repository_url
    region              = local.region
    account_id          = local.account_id  
    log_group           = aws_cloudwatch_log_group.jenkins_controller_log_group.name
    #log_group           = "${var.name_prefix}"
    memory              = var.jenkins_controller_memory
    cpu                 = var.jenkins_controller_cpu
  }
}

resource "aws_kms_key" "cloudwatch" {
  description  = "KMS for cloudwatch log group"
  policy  = data.aws_iam_policy_document.cloudwatch.json
  tags    = var.tags
}

resource "aws_cloudwatch_log_group" jenkins_controller_log_group {
  name              = var.name_prefix
  retention_in_days = var.jenkins_controller_task_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn
  tags              = var.tags
}

resource "aws_ecs_task_definition" jenkins_controller {
  family = var.name_prefix

  task_role_arn            = var.jenkins_controller_task_role_arn != null ? var.jenkins_controller_task_role_arn : aws_iam_role.jenkins_controller_task_role.arn
  execution_role_arn       = var.ecs_execution_role_arn != null ? var.ecs_execution_role_arn : aws_iam_role.ecs_execution_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.jenkins_controller_cpu
  memory                   = var.jenkins_controller_memory
  container_definitions    = data.template_file.jenkins_controller_container_def.rendered

  volume {
    name = "${var.name_prefix}-efs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      root_directory     = "/jenkins_home"
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }

  tags = var.tags
}


// ECS Service
resource "aws_ecs_service" jenkins_controller {
  name = "${var.name_prefix}-controller"

  task_definition  = aws_ecs_task_definition.jenkins_controller.arn
  cluster          = aws_ecs_cluster.jenkins_controller.id
  desired_count    = 1
  launch_type      = "EC2"
  iam_role         =  "${aws_iam_role.ecs_service_role.arn}"

  load_balancer {
    #target_group_arn = aws_elb.elb.arn
    elb_name         = aws_elb.elb.name
    container_name   = "${var.name_prefix}-controller"
    container_port   = var.jenkins_controller_port
  }

  # To prevent a race condition during service deletion, make sure to set depends_on to the related aws_iam_policy; 
  # otherwise, the policy may be destroyed too soon and the ECS service will then get stuck in the DRAINING state.
  #depends_on = [aws_lb_listener.https]
  depends_on = [aws_ecs_cluster.jenkins_controller,aws_ecs_task_definition.jenkins_controller,aws_iam_policy.ecs_service_policy]
  
  enable_ecs_managed_tags = true
  propagate_tags = "TASK_DEFINITION"

  tags = var.tags
}
