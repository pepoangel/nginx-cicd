# Recurso de clúster ECS
resource "aws_ecs_cluster" "nginx_cluster" {
  name = "nginx-cluster"
}

# Recurso de definición de tarea ECS
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  network_mode             = "awsvpc"

  container_definitions = <<DEFINITION
    [
      {
        "name": "nginx-container",
        "image": "nginx:latest",
        "portMappings": [
          {
            "containerPort": 80,
            "hostPort": 80
          }
        ],
        "memory": 512,
        "cpu": 256
      }
    ]
  DEFINITION
}

# Recurso de servicio ECS
resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets         = ["SUBNET_ID"]
    security_groups = ["SECURITY_GROUP_ID"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "TARGET_GROUP_ARN"
    container_name   = "nginx-container"
    container_port   = 80
  }
}

# Recurso de rol IAM para la ejecución de tareas ECS
resource "aws_iam_role" "task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Asociar política de servicio de contenedor de ECS al rol IAM de ejecución de tareas
resource "aws_iam_role_policy_attachment" "task_execution_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
