module "concourse-ecs-alb" {
  source = "../ecs-alb"

  healthchecks = {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 3
      path                = "/public/images/favicon.png"
      protocol            = "HTTP"
      port                = "8080"
      interval            = 5
      matcher             = "200,401,302"
  }
    
  elb_instance_port               = "8080"
  healthcheck_protocol            = "HTTP"
  healthcheck_path                = "/public/images/favicon.png"
  task_definition                 = "concourse-${var.context.environment.name}:${aws_ecs_task_definition.concourse.revision}"
  task_status                     = var.task_status
  aws_lb_listener_rule_priority   = 98
  aws_lb_listener_default_arn     = var.aws_lb_listener_default_arn
  aws_route53_environment_zone_id = var.aws_route53_environment_zone_id
  aws_alb_default_dns_name        = var.aws_alb_default_dns_name
  vpc_id                          = var.vpc_id
  product                         = var.context.product.name
  environment                     = var.context.environment.name
  root_domain_name                = var.context.product.root_domain_name
  ecs_iam_role                    = var.ecs_iam_role
  role                            = "concourse"
  cluster_name                    = "default"
}

resource "aws_ecs_task_definition" "concourse" {
  family       = "concourse-${var.context.environment.name}"
  network_mode = "host"

  volume {
    name      = "consul_config"
    host_path = "/etc/consul"
  }

  volume {
    name      = "goss_config"
    host_path = "/etc/goss"
  }

  depends_on = [aws_db_instance.concourse]

  container_definitions = <<DEFINITION
    [
        {
            "name": "concourse",
            "cpu": 0,
            "essential": true,
            "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/concourse-web:${var.docker_tag}",
            "memory": 500,
            "dnsServers": ["127.0.0.1"],
            "portMappings": [
                {
                  "hostPort": 8080,
                  "containerPort": 8080,
                  "protocol": "tcp"
                },
                {
                  "hostPort": 2222,
                  "containerPort": 2222,
                  
                  "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "Name": "CONCOURSE_BASIC_AUTH_USERNAME",
                    "Value": "concourse"
                }, 
                {
                    "Name": "CONCOURSE_BASIC_AUTH_PASSWORD",
                    "Value": "${var.concourse_password}"
                }, 
                {
                    "Name": "CONCOURSE_EXTERNAL_URL",
                    "Value": "http://concourse.${var.context.environment.name}.${var.aws_alb_default_dns_name}"
                }, 
                {
                    "Name": "CONCOURSE_POSTGRES_HOST",
                    "Value": "${aws_db_instance.concourse.address}"
                }, 
                {
                    "Name": "CONCOURSE_POSTGRES_USER",
                    "Value": "concourse"
                }, 
                {
                    "Name": "CONCOURSE_POSTGRES_PASSWORD",
                    "Value": "${var.concourse_postgres_password}"
                }, 
                {
                    "Name": "CONCOURSE_POSTGRES_DATABASE",
                    "Value": "concourse"
                }, 
                {
                    "Name": "CONCOURSE_PORT",
                    "Value": "8085"
                }
            ],
            "mountPoints": [
                {
                  "sourceVolume": "consul_config",
                  "containerPath": "/etc/consul",
                  "readOnly": false
                },
                {
                  "sourceVolume": "goss_config",
                  "containerPath": "/etc/goss",
                  "readOnly": false
                }
            ]            
        }
    ]
    
DEFINITION

}

resource "aws_security_group" "concourse" {
  name = "concourse"

  description = "concourse security group"
  vpc_id = var.vpc_id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2222
    to_port = 2222
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2222
    to_port = 2222
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "concourse-${var.context.product.name}-${var.context.environment.name}"
    Product = var.context.product.name
    Environment = var.context.environment.name
    Layer = "concourse"
  }

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_db_subnet_group" "concourse_db" {
  name = "concourse-db-${var.context.environment.name}"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "concourse_db" {
  name = "concourse-db-${var.context.environment.name}"

  description = "dashing security group"
  vpc_id = var.vpc_id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgres-${var.context.product.name}-${var.context.environment.name}"
    Product = var.context.product.name
    Environment = var.context.environment.name
  }
}

resource "aws_db_instance" "concourse" {
  identifier = "${var.context.product.name}-${var.context.environment.name}"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "9.6.11"
  instance_class = "db.t2.micro"
  name = "concourse"
  username = "concourse"
  db_subnet_group_name = aws_db_subnet_group.concourse_db.name
  password = var.concourse_postgres_password
  parameter_group_name = "default.postgres9.6"
  vpc_security_group_ids = [aws_security_group.concourse_db.id]
  skip_final_snapshot = true
}

