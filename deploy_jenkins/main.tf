data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  account_id      = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  name_prefix     = "cm-jenkins-master"
  env             = "prod"
  product         = "jenkins"
  uai             = "UAI1010163"

  tags = {
    Name             = "${local.name_prefix}"
    Environment      = "${local.env}"
    Product          = "${local.product}"
    UAI              = "${local.uai}"
  }
}

#module myip {
 # source  = "4ops/myip/http"
  #version = "1.0.0"
#}


#// An example of creating a KMS key
resource "aws_kms_key" "efs_kms_key" {
  description = "KMS key used to encrypt Jenkins EFS volume"
  tags = local.tags
}

module "serverless_jenkins" {
  source                          = "../modules/jenkins_platform"
  name_prefix                     = local.name_prefix
  tags                            = local.tags
  vpc_id                          = var.vpc_id
  efs_kms_key_arn                 = aws_kms_key.efs_kms_key.arn
  efs_subnet_ids                  = var.efs_subnet_ids
  jenkins_controller_subnet_ids   = var.jenkins_controller_subnet_ids
  alb_subnet_ids                  = var.alb_subnet_ids
  alb_ingress_allow_cidrs         = ["0.0.0.0/0"]
  alb_acm_certificate_arn         = "arn:aws:acm:us-east-1:806483491539:certificate/a434e826-52e1-4793-a400-9394fa44c577"
  // Launch Template instance key-pair
  key_name                        = "ECS-key"
  // tags parameters
  environment                     = local.env
  product                         = local.product
  uai                             = local.uai

}