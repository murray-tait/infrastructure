output "dashing_task_count" {
   value = "${module.dashing-ecs-alb.task_count}"
}

output "nexus_task_count" {
   value = "${module.nexus-ecs-alb.task_count}"
}

output "concourse_task_count" {
   value = "${module.concourse-ecs-alb.task_count}"
}

output "monitoring_task_count" {
   value = "${module.monitoring-ecs-alb.task_count}"
}

