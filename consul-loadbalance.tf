resource "aws_lb_cookie_stickiness_policy" "consului" {
  name                     = "consului"
  load_balancer            = "${aws_elb.consului.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}

resource "aws_elb" "consului" {
  name            = "consului"
  security_groups = ["${aws_security_group.consului.id}"]
  subnets = ["${aws_subnet.consul.id}"]
  depends_on = ["aws_security_group.consului"]
  
  listener {
    instance_port      = 8500
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }  

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8500/v1/agent/checks"
    interval            = 30
  }
}

resource "aws_route53_record" "consul" {
	zone_id = "${aws_route53_zone.root.zone_id}"
	name    = "consul"
    type    = "A"
    depends_on = ["aws_route53_zone.root", "aws_elb.consului"]

	alias {
		 name = "${aws_elb.consului.dns_name}"
		 zone_id = "${aws_elb.consului.zone_id}"
		 evaluate_target_health = "true"
	}
}