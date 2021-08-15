[
    {
      "name": "${name}",
      "image": "${container_image}",
      "cpu": ${cpu},
      "memory": ${memory},
      "memoryReservation": ${memory},
      "environment": [],
      "essential": true,
      "mountPoints": [
        {
          "containerPath": "${jenkins_home}",
          "sourceVolume": "${source_volume}"
        }
      ],
      "portMappings": [
        {
          "hostPort": ${jenkins_controller_port},
          "containerPort": ${jenkins_controller_port},
          "protocol": "tcp"
        },
        {
          "hostPort": ${jnlp_port},
          "containerPort": ${jnlp_port},
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${log_group}",
            "awslogs-region": "${region}",
            "awslogs-stream-prefix": "controller"
        }
      },
      "secrets": []
    }
]