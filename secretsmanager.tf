resource "aws_secretsmanager_secret" "invoice_me" {
  name = "${var.app_name}"
}

resource "aws_secretsmanager_secret_version" "invoice_me" {
  secret_id     = "${aws_secretsmanager_secret.invoice_me.id}"
  secret_string = "${jsonencode(var.secrets)}"
}

variable "secrets" {
  default = {
    harvest_auth = ""
    slack_webhook = ""
  }
  type = "map"
}