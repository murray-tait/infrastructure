#!/bin/bash

set -e

vars=""

while test $# -gt 0
do
    case "$1" in
        nexus) 
            terraform apply -auto-approve -target=module.nexus.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf -var 'nexus_task_status=down'
            ;;
        concourse) 
            terraform apply -auto-approve -target=module.concourse.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf -var 'concourse_task_status=down'
            ;;
        dashing) 
            terraform apply -auto-approve -target=module.dashing.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf -var 'dashing_task_status=down'
            ;;
        monitoring) 
            terraform apply -auto-approve -target=module.monitoring.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf -var 'monitoring_task_status=down'
            ;;
    esac
    
    shift
done

sleep 90

terraform apply -auto-approve -target=module.nexus.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf
terraform apply -auto-approve -target=module.concourse.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf
terraform apply -auto-approve -target=module.dashing.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf
terraform apply -auto-approve -target=module.monitoring.aws_ecs_service.this -state=terraform.tfstate -var-file=dev_config.vartf
