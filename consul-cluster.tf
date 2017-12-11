resource "aws_ecs_cluster" "consul-leader" {
  name = "consul-leader"
}

resource "aws_ecs_service" "consul-leader" {
  name            = "consul-leader"
  cluster         = "consul-leader"
  task_definition = "consul-leader:${aws_ecs_task_definition.consul-leader.revision}"
  depends_on = ["aws_ecs_cluster.consul-leader", "aws_ecs_task_definition.consul-leader"]
  desired_count   = 1
}

resource "aws_ecs_task_definition" "consul-leader" {
  family = "consul-leader"
  network_mode = "host"
  
  container_definitions = <<DEFINITION
	[
		{
			"name": "collectd",
			"cpu": 0,
		    "essential": true,
		    "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/collectd-write-graphite:0.1.1",
		    "memory": 500,
		    "environment": [
		    	{
		    		"Name": "HOST_NAME",
		    		"Value": "consul-leader"
		    	},
		    	{
		    		"Name": "GRAPHITE_HOST",
		    		"Value": "10.0.0.80"
		    	}, 
		    	{
		    		"Name": "GRAPHITE_PREFIX",
		    		"Value": "${var.ecosystem}.${var.environment}.consul."
		    	}
		    ]
		},
		{
		    "name": "consul-leader",
		    "cpu": 0,
		    "essential": true,
		    "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/consul:0.1.1",
		    "memory": 500,
		    "environment": [
		    	{
		    		"Name": "CONSUL_LOCAL_CONFIG",
		    		"Value": "{\"skip_leave_on_interrupt\": true}"
		    	},
		    	{
		    		"Name": "CONSUL_BIND_INTERFACE",
		    		"Value": "eth0"
		    	}, 
		    	{
		    		"Name": "CONSUL_CLIENT_INTERFACE",
		    		"Value": "eth0"
		    	}
		    ],
		    "command": [
        		"agent",
        		"-server",
        		"-bootstrap",
        		"-retry-join",
        		"provider=aws tag_key=ConsulCluster tag_value=${var.nameTag}",
        		"-ui"
      		],
		    "portMappings": [
		        {
		          "hostPort": 8300,
		          "containerPort": 8300,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8301,
		          "containerPort": 8301,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8301,
		          "containerPort": 8301,
		          "protocol": "udp"
		        },
		        {
		          "hostPort": 8302,
		          "containerPort": 8302,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8302,
		          "containerPort": 8302,
		          "protocol": "udp"
		        },
		        {
		          "hostPort": 8500,
		          "containerPort": 8500,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8600,
		          "containerPort": 8600,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8600,
		          "containerPort": 8600,
		          "protocol": "udp"
		        }
		    ]
      	}
	]
    DEFINITION
}

resource "aws_ecs_cluster" "consul-server" {
  name = "consul-server"
}

resource "aws_ecs_service" "consul-server" {
  name            = "consul-server"
  cluster         = "consul-server"
  task_definition = "consul-server:${aws_ecs_task_definition.consul-server.revision}"
  depends_on = ["aws_ecs_cluster.consul-server", "aws_ecs_task_definition.consul-server"]
  desired_count   = 2
}

resource "aws_ecs_task_definition" "consul-server" {
  family = "consul-server"
  network_mode = "host"
  
  container_definitions = <<DEFINITION
	[
		{
			"name": "collectd",
			"cpu": 0,
		    "essential": true,
		    "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/collectd-write-graphite:0.1.1",
		    "memory": 500,
		    "environment": [
		    	{
		    		"Name": "GRAPHITE_HOST",
		    		"Value": "10.0.0.80"
		    	}, 
		    	{
		    		"Name": "GRAPHITE_PREFIX",
		    		"Value": "${var.ecosystem}.${var.environment}.consul."
		    	}
		    ]
		},
		{
		    "name": "consul-server",
		    "cpu": 0,
		    "essential": true,
		    "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/consul:0.1.0",
		    "memory": 500,
		    "environment": [
		    	{
		    		"Name": "CONSUL_LOCAL_CONFIG",
		    		"Value": "{\"skip_leave_on_interrupt\": true}"
		    	},
		    	{
		    		"Name": "CONSUL_BIND_INTERFACE",
		    		"Value": "eth0"
		    	}, 
		    	{
		    		"Name": "CONSUL_CLIENT_INTERFACE",
		    		"Value": "eth0"
		    	}
		    ],
		    "command": [
        		"agent",
        		"-server",
        		"-retry-join",
        		"provider=aws tag_key=ConsulCluster tag_value=${var.nameTag}",
        		"-ui"
      		],
		    "portMappings": [
		        {
		          "hostPort": 8300,
		          "containerPort": 8300,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8301,
		          "containerPort": 8301,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8301,
		          "containerPort": 8301,
		          "protocol": "udp"
		        },
		        {
		          "hostPort": 8302,
		          "containerPort": 8302,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8302,
		          "containerPort": 8302,
		          "protocol": "udp"
		        },
		        {
		          "hostPort": 8500,
		          "containerPort": 8500,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8600,
		          "containerPort": 8600,
		          "protocol": "tcp"
		        },
		        {
		          "hostPort": 8600,
		          "containerPort": 8600,
		          "protocol": "udp"
		        }
		    ]
      	}
	]
    DEFINITION
}
