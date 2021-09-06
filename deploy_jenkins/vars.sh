#!/usr/bin/env bash

# export TERRAFORM_WORKSPACE=jason-local-farm-runner
export TF_STATE_BUCKET="terraform-state-450"
export TF_STATE_OBJECT_KEY="terraform/jenkinsstate"
export AWS_REGION="us-east-1"

#PRIVATE_SUBNETS='["subnet-02970ee28b3d0282f","subnet-0f287d8edcffb91f9"]'
PRIVATE_SUBNETS='["subnet-060586d9be5b6ed9e","subnet-0ac1fb98cb711c23b"]'
PUBLIC_SUBNETS='["subnet-060586d9be5b6ed9e","subnet-0ac1fb98cb711c23b"]'

export TF_VAR_vpc_id="vpc-030210a94e6675ff6"
export TF_VAR_efs_subnet_ids=${PRIVATE_SUBNETS}
export TF_VAR_jenkins_controller_subnet_ids=${PRIVATE_SUBNETS}
export TF_VAR_alb_subnet_ids=${PUBLIC_SUBNETS}
export TF_LOG=DEBUG
export TF_LOG_PATH=tf_debug.txt
