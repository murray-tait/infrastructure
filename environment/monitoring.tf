module "monitoring" {
  source = "../role"

  role = "monitoring"

  vpc_security_group_ids = [
    "${aws_security_group.graphite.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.consul-client.id}",
  ]

  elb_instance_port    = "3000"
  healthcheck_protocol = "HTTP"
  healthcheck_path     = "/api/health"
  task_definition      = "monitoring-${var.environment}:${aws_ecs_task_definition.monitoring.revision}"
  task_status          = "${var.monitoring_task_status}"

  volume_id = "${var.monitoring_volume_id}"

  // globals
  aws_lb_listener_default_arn = "${aws_alb_listener.default.arn}"
  aws_lb_listener_rule_priority = 96
  key_name                 = "${var.key_name}"
  aws_subnet_id            = "${aws_subnet.av1.id}"
  vpc_id                   = "${aws_vpc.default.id}"
  gateway_id               = "${aws_internet_gateway.default.id}"
  availability_zone        = "${var.availability_zone_1}"
  ami_id                   = "${var.ecs_ami_id}"
  product                  = "${var.product}"
  environment              = "${var.environment}"
  aws_route53_zone_id      = "${aws_route53_zone.environment.zone_id}"
  aws_alb_default_dns_name = "${aws_alb.default.dns_name}"
  root_domain_name         = "${var.root_domain_name}"
}

data "template_file" "collectd-monitoring" {
  template = "${file("${path.module}/files/collectd.tpl")}"

  vars {
    graphite_prefix = "${var.product}.${var.environment}.monitoring."
    collectd_docker_tag = "${var.collectd_docker_tag}"
  }
}

resource "aws_ecs_task_definition" "monitoring" {
  family       = "monitoring-${var.environment}"
  network_mode = "host"

  volume {
    name      = "consul_config"
    host_path = "/opt/consul/conf"
  }

  volume {
    name      = "grafana_data"
    host_path = "/opt/mount1/grafana"
  }

  volume {
    name      = "grafana_plugins"
    host_path = "/opt/mount1/grafana/plugins"
  }

  volume {
    name      = "grafana_logs"
    host_path = "/opt/mount1/grafana_logs"
  }

  volume {
    name      = "graphite_config"
    host_path = "/opt/mount1/graphite/conf"
  }

  volume {
    name      = "graphite_stats_storage"
    host_path = "/opt/mount1/graphite/storage"
  }

  volume {
    name      = "nginx_config"
    host_path = "/opt/mount1/nginx_config"
  }

  volume {
    name      = "statsd_config"
    host_path = "/opt/mount1/statsd_config"
  }

  volume {
    name      = "graphite_logrotate_config"
    host_path = "/etc/logrotate.d"
  }

  volume {
    name      = "graphite_log_files"
    host_path = "/opt/mount1/graphite_log_files"
  }

  container_definitions = <<DEFINITION
	[
        ${data.template_file.consul_agent.rendered},
        ${data.template_file.collectd-monitoring.rendered},
		{
		    "name": "graphite-statsd",
		    "cpu": 0,
		    "essential": true,
		    "image": "graphiteapp/graphite-statsd:1.1.3",
		    "memory": 400,
		    "portMappings": [
		        {
		          "hostPort": 80,
		          "containerPort": 80,
		          "protocol": "tcp"
		        },
                {
                  "hostPort": 82,
                  "containerPort": 82,
                  "protocol": "tcp"
                },
		        {
		          "hostPort": 2003,
		          "containerPort": 2003,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 2004,
		          "containerPort": 2004,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 2023,
		          "containerPort": 2023,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 2024,
		          "containerPort": 2024,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8125,
		          "containerPort": 8125,
		          "protocol": "udp"
		        },
		        {
		          "hostPort": 8126,
		          "containerPort": 8126,
		          "protocol": "udp"
		        }
		    ],
			"mountPoints": [
                {
                  "sourceVolume": "graphite_config",
                  "containerPath": "/opt/graphite/conf",
                  "readOnly": false
                },
                {
                  "sourceVolume": "graphite_stats_storage",
                  "containerPath": "/opt/graphite/storage",
                  "readOnly": false
                },
                {
                  "sourceVolume": "nginx_config",
                  "containerPath": "/etc/nginx",
                  "readOnly": false
                },
                {
                  "sourceVolume": "statsd_config",
                  "containerPath": "/opt/statsd",
                  "readOnly": false
                },
                {
                  "sourceVolume": "graphite_logrotate_config",
                  "containerPath": "/etc/logrotate.d",
                  "readOnly": false
                },
                {
                  "sourceVolume": "graphite_log_files",
                  "containerPath": "/var/log/graphite",
                  "readOnly": false
                }
            ]
        },
		{
		    "name": "grafana",
		    "cpu": 0,
		    "essential": true,
		    "image": "grafana/grafana:5.1.0",
		    "memory": 500,
		    "portMappings": [
		        {
		          "hostPort": 3000,
		          "containerPort": 3000,
		          "protocol": "udp"
		        }
		    ],
		    "mountPoints": [
                {
                  "sourceVolume": "grafana_data",
                  "containerPath": "/var/lib/grafana/",
                  "readOnly": false
                },
                {
                  "sourceVolume": "grafana_plugins",
                  "containerPath": "/var/lib/grafana/plugins",
                  "readOnly": false
                },
                {
                  "sourceVolume": "grafana_logs",
                  "containerPath": "/var/log/grafana",
                  "readOnly": false
                }
            ]
      	}
	]
    DEFINITION
}

resource "aws_security_group" "graphite" {
  name = "graphite-${var.product}-${var.environment}"

  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port   = 2003
    to_port     = 2003
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}", "${var.admin_cidr}"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}", "${var.admin_cidr}"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}", "${var.admin_cidr}"]
  }

  tags {
    Name        = "graphite-${var.product}-${var.environment}"
    Product     = "${var.product}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "grafana" {
  name = "grafana"

  description = "grafana security group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${concat(var.monitoring_cidrs, list(var.admin_cidr))}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "grafana-${var.product}-${var.environment}"
    Product     = "${var.product}"
    Environment = "${var.environment}"
    Layer       = "grafana"
  }
}
