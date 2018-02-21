variable "consul_server_instance_names" {
  default = {
    "0" = "1"
    "1" = "2"
    "2" = "3"
  }
}

resource "aws_instance" "consul-leader" {
	count = "1"
	ami = "${var.ecs_ami_id}"
	availability_zone = "${var.availability_zone}"
	tenancy = "default",
	ebs_optimized = "false",
	disable_api_termination = "false",
    instance_type= "t2.small"
    key_name = "poc"
    private_ip = "${var.consul_leader_ip}"
    monitoring = "false",
    vpc_security_group_ids = [
    	"${aws_security_group.ssh.id}",
    	"${aws_security_group.consul-server.id}"
    ],
    subnet_id = "${aws_subnet.consul.id}",
    associate_public_ip_address = "true"
	source_dest_check = "true",
	iam_instance_profile = "ecsinstancerole",
	ipv6_address_count = "0",
    depends_on      = ["aws_security_group.consul-server", "aws_security_group.ssh", "aws_subnet.consul"]
	user_data = <<EOF
#!/bin/bash
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=consul-leader
HOSTNAME=consul-${var.nameTag}-leader
EOF

  tags {
    Name = "consul-0"
	Ecosystem = "${var.ecosystem}"
	Environment = "${var.environment}"
	ConsulCluster = "${var.nameTag}"
  }
}

resource "aws_elb_attachment" "consul-leader" {
  elb      = "${aws_elb.consului.id}"
  instance = "${aws_instance.consul-leader.id}"
}

resource "aws_instance" "consul-server" {
  count = "${var.consul_server_count}" 
	ami = "${var.ecs_ami_id}"
	availability_zone = "${var.availability_zone}"
	tenancy = "default",
	ebs_optimized = "false",
	disable_api_termination = "false",
    instance_type= "t2.small"
    key_name = "poc"
    private_ip = "${lookup(var.consul_server_instance_ips, count.index)}"
    monitoring = "false",
    vpc_security_group_ids = [
    	"${aws_security_group.ssh.id}",
    	"${aws_security_group.consul-server.id}"
    ],
    subnet_id = "${aws_subnet.consul.id}",
    associate_public_ip_address = "true"
	source_dest_check = "true",
	iam_instance_profile = "ecsinstancerole",
	ipv6_address_count = "0",
    depends_on      = ["aws_security_group.consul-server", "aws_security_group.ssh", "aws_subnet.consul"]
	user_data = <<EOF
#!/bin/bash
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=consul-server
HOST_NAME=consul-${var.nameTag}-${lookup(var.consul_server_instance_names, count.index)}
EOF

  tags {
    Name = "consul-${lookup(var.consul_server_instance_names, count.index)}"
	Ecosystem = "${var.ecosystem}"
	Environment = "${var.environment}"
	ConsulCluster = "${var.nameTag}"
  }
}

resource "aws_elb_attachment" "consul-server" {
  count = "${var.consul_server_count}" 
  elb      = "${aws_elb.consului.id}"
  instance = "${aws_instance.consul-server.*.id[count.index]}"
}

