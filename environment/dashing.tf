module "dashing-ecs-alb" {
  source = "../ecs-alb"

  elb_instance_port               = "80"
  healthcheck_protocol            = "HTTP"
  healthcheck_path                = "/favicon.ico"
  task_definition                 = "dashing-${local.environment}:${aws_ecs_task_definition.dashing.revision}"
  task_status                     = "${var.dashing_task_status}"
  aws_lb_listener_default_arn     = "${aws_alb_listener.default.arn}"
  aws_lb_listener_rule_priority   = 97
  aws_route53_environment_zone_id = "${aws_route53_zone.environment.zone_id}"
  aws_alb_default_dns_name        = "${aws_alb.default.dns_name}"
  vpc_id                          = "${aws_vpc.default.id}"
  role                            = "dashing"
  product                         = "${local.product}"
  environment                     = "${local.environment}"
  root_domain_name                = "${local.root_domain_name}"
  cluster_name                    = "default"
}

resource "aws_ecs_task_definition" "dashing" {
  family       = "dashing-${local.environment}"
  network_mode = "bridge"

  volume {
    name      = "consul_config"
    host_path = "/etc/consul"
  }

  volume {
    name      = "goss_config"
    host_path = "/etc/goss"
  }

  container_definitions = <<DEFINITION
    [
        {
            "name": "dashing",
            "cpu": 0,
            "essential": true,
            "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/smashing:${var.dashing_docker_tag}",
            "memory": 200,
            "environment": [
                {
                    "Name": "PORT",
                    "Value": "80"
                }
             ], 
            "portMappings": [
                {
                  "hostPort": 80,
                  "containerPort": 80,
                  "protocol": "tcp"
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

resource "aws_security_group" "dashing" {
  name = "dashing"

  description = "dashing security group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "dashing-${local.product}-${local.environment}"
    Product     = "${local.product}"
    Environment = "${local.environment}"
    Layer       = "dashing"
  }
}
