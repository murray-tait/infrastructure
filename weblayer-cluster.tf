resource "aws_ecs_cluster" "weblayer" {
  name = "weblayer"
}

resource "aws_ecs_service" "weblayer" {
  name            = "weblayer"
  cluster         = "weblayer"
  task_definition = "weblayer:${aws_ecs_task_definition.weblayer.revision}"
  desired_count   = 1
}

resource "aws_ecs_task_definition" "weblayer" {
  family = "weblayer"
  network_mode = "bridge"
  
  container_definitions = <<DEFINITION
	[
		{
		    "name": "web_layer",
		    "cpu": 0,
		    "essential": true,
		    "image": "453254632971.dkr.ecr.eu-west-1.amazonaws.com/greeting:0.0.1-SNAPSHOT",
		    "memory": 128,
		    "portMappings": [
		    	{
		    		"containerPort": 8080,
		    		"hostPort": 80
		    	}
		    ]
		}
	]
DEFINITION
}

