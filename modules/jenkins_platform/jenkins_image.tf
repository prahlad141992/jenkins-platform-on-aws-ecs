data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_endpoint = split("/", aws_ecr_repository.jenkins_controller.repository_url)[0]
}


resource "aws_ecr_repository" "jenkins_controller" {
  #name                 =  var.jenkins_ecr_repository_name
  name                  = "${var.name_prefix}-main"
  image_tag_mutability = "MUTABLE"

  #image_scanning_configuration  {
   #   scan_on_push = true
  #}

}

resource "aws_ecr_repository" "jenkins_agent" {
  #name                 =  var.jenkins_ecr_repository_name
  name                  = "${var.name_prefix}-agent"
  image_tag_mutability = "MUTABLE"

  #image_scanning_configuration  {
   #   scan_on_push = true
  #}

}

resource "null_resource" "build_docker_image" {

  provisioner "local-exec" {
    command = <<EOF
docker login -u AWS -p ${data.aws_ecr_authorization_token.token.password} ${local.ecr_endpoint} && docker build -t ${aws_ecr_repository.jenkins_controller.repository_url}:latest -f ${path.module}/docker/controller.Dockerfile . && docker build -t ${aws_ecr_repository.jenkins_agent.repository_url}:latest -f ${path.module}/docker/agent.Dockerfile . && docker push ${aws_ecr_repository.jenkins_controller.repository_url}:latest && docker push ${aws_ecr_repository.jenkins_agent.repository_url}:latest
EOF
  }
}
