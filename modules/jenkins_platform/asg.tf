# launch templates
#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
# Lookup the correct AMI based on the region specified
# aws ec2 describe-images --region us-east-1 --image-ids ami-xxxxxx
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

/*
resource "aws_launch_configuration" "ecs-launch-configuration" {
    name                       = "ECS-${var.name_prefix}-InstanceLc-${random_id.fakeuuid.hex}"
    #image_id                  =  data.aws_ami.amazon_linux_ecs.id
    image_id                   = "ami-01453e60fc2aef31b"
    instance_type              = "${var.instance_type}"
    iam_instance_profile       = "${var.role_name}"
    #ebs_optimized             = true   

    root_block_device {
      volume_type = "gp2"
      volume_size = "${var.volume_size}"
      delete_on_termination = true
      encrypted   = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.jenkins_controller_security_group.id}"]
    associate_public_ip_address = "true"
    key_name                    = "${var.key_name}"
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${var.name_prefix}-main >> /etc/ecs/ecs.config
                                  EOF
}

*/

data "template_file" user_data {
  template = file("${path.module}/templates/user_data.tpl")
  vars = {
      cluster_name  = "${var.name_prefix}-main"
  }
}

resource "aws_launch_template" "launch_template" {

    name                        = "${var.name_prefix}-ECSInstanceLT-${random_id.fakeuuid.hex}"
    description                 = "${var.name_prefix} launch template"
    image_id                   =  data.aws_ami.amazon_linux_ecs.id
    #image_id                    = "ami-01453e60fc2aef31b"
    instance_type               = "${var.instance_type}"
    key_name                    = "${var.key_name}"
    #ebs_optimized               = true
    
    monitoring {
    enabled = true
    }

    iam_instance_profile {
        #arn      = "${var.role_name}"
        arn       = "${aws_iam_instance_profile.ecs_instance_profile.arn}"
    } 

    block_device_mappings {
        # Root volume
        device_name = "/dev/xvda"
        no_device   = 0
        ebs {
            volume_type = "gp2"
            volume_size = "${var.volume_size}"
            encrypted   = true
            delete_on_termination = true
            }
    }

    network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = ["${aws_security_group.jenkins_controller_security_group.id}"]
  }

    lifecycle {
      create_before_destroy = true
    }


    #vpc_security_group_ids      = ["${aws_security_group.jenkins_controller_security_group.id}"]
    user_data                   = base64encode("${data.template_file.user_data.rendered}")
    
    // tags apply to resources.
    tag_specifications {
    resource_type = "instance"
    tags = var.tags
    }
     
    tag_specifications {
    resource_type = "volume"
    tags = var.tags
    }
    
    tag_specifications {
    resource_type = "network-interface"
    tags = var.tags
    }

    tags = var.tags
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
    name                        = "${var.name_prefix}-ECSInstanceAsg-${random_id.fakeuuid.hex}"
    max_size                    = "${var.max_instance_size}"
    min_size                    = "${var.min_instance_size}"
    desired_capacity            = "${var.desired_capacity}"
    vpc_zone_identifier         = "${var.jenkins_controller_subnet_ids}"
    health_check_type           = "EC2"
    #launch_configuration        = "${aws_launch_configuration.ecs-launch-configuration.name}"
     
    launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
    }

    lifecycle {
      create_before_destroy = true
    }

    // tags apply to ASG.
    tags = [
    {
      key                 = "Name"
      value               = "${var.name_prefix}"
      propagate_at_launch = false
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = false
    },
    {
      key                 = "Product"
      value               = "${var.product}"
      propagate_at_launch = false
    },
    {
      key                 = "UAI"
      value               = "${var.uai}"
      propagate_at_launch = false
    }
  ]

}

resource "random_id" "fakeuuid" {
  keepers = {
    # Generate a new id each time only when new value is specified
    # This will allow reuse of ELBs and security groups unless
    # a new unique value variable is chosen.
    ami_id              = "${var.name_prefix}"
  }

  byte_length = 8
}
