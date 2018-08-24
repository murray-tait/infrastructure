locals {
  nexus_volume_id = "${var.globals["nexus_volume_id"]}"
  monitoring_volume_id = "${var.globals["monitoring_volume_id"]}"
  key_name = "${var.globals["key_name"]}"
  root_domain_name = "${var.globals["root_domain_name"]}"
  product = "${var.globals["product"]}"
  environment = "${var.globals["environment"]}"
  nameTag = "${var.globals["nameTag"]}"
  admin_cidr = "${var.globals["admin_cidr"]}"

  concourse_postgres_password = "${var.secrets["concourse_postgres_password"]}"
  concourse_password = "${var.secrets["concourse_password"]}"
  aws-proxy_access_id = "${var.secrets["aws-proxy_access_id"]}"
  aws-proxy_secret_access_key = "${var.secrets["aws-proxy_secret_access_key"]}"
  prometheus_access_id = "${var.secrets["prometheus_access_id"]}"
  prometheus_secret_access_key = "${var.secrets["prometheus_secret_access_key"]}"
  concourse_tsa_host_key_value = "${var.secrets["concourse_tsa_host_key_value"]}"
  concourse_tsa_authorized_keys_value = "${var.secrets["concourse_tsa_authorized_keys_value"]}"
  concourse_session_signing_key_value = "${var.secrets["concourse_session_signing_key_value"]}"
  concourse_tsa_public_key_value = "${var.secrets["concourse_tsa_public_key_value"]}"
  concourse_tsa_worker_private_key_value = "${var.secrets["concourse_tsa_worker_private_key_value"]}"
}