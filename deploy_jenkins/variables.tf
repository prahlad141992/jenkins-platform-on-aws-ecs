variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to add to ECS Cluster"
  type        = map(string)
  default     = {}
}

variable vpc_id {
  type        = string
  description = "The vpc id for where jenkins will be deployed"
}

variable efs_subnet_ids {
  type        = list(string)
  description = "A list of subnets to attach to the EFS mountpoint. Should be private"
#   default = ["subnet-5d12c221","subnet-2178df6d","subnet-29452043"]
}

variable jenkins_controller_subnet_ids {
  type        = list(string)
  description = "A list of subnets for the jenkins controller fargate service. Should be private"
#   default = ["subnet-5d12c221","subnet-2178df6d","subnet-29452043"]
}

variable alb_subnet_ids {
  type        = list(string)
  description = "A list of subnets for the Application Load Balancer"
   #default = ["subnet-5d12c221","subnet-2178df6d","subnet-29452043"]
}
