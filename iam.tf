resource "aws_iam_role" "lambda_exec_role" {
  name        = "${var.app_name}"
  path        = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "s3-access-rw" {
    statement {
        actions = [
            "s3:ListBucket"
        ]
        resources = [
            "${aws_s3_bucket.bucket.arn}",
        ]
    }
    statement {
        actions = [
            "s3:PutObject",
            "s3:GetObject" 
        ]
        resources = [
            "${aws_s3_bucket.bucket.arn}/*",
        ]
    }
}

data "aws_iam_policy_document" "dynamo-access-rw" {
    statement {
        actions = [
            "dynamodb:GetItem",
            "dynamodb:UpdateItem"
        ]
        resources = [
            "${aws_dynamodb_table.table.arn}",
        ]
    }
}

data "aws_iam_policy_document" "secretsmanager-access-r" {
    statement {
        actions = [
            "secretsmanager:GetSecretValue"
        ]
        resources = [
            "${aws_secretsmanager_secret.invoice_me.arn}",
        ]
    }
}

resource "aws_iam_policy" "s3-access-rw" {
    name   = "invoiceme-s3-access-rw"
    path   = "/"
    policy = "${data.aws_iam_policy_document.s3-access-rw.json}"
}

resource "aws_iam_policy" "dynamo-access-rw" {
    name   = "invoiceme-dynamo-access-rw"
    path   = "/"
    policy = "${data.aws_iam_policy_document.dynamo-access-rw.json}"
}

resource "aws_iam_policy" "secretsmanager-access-r" {
    name   = "invoiceme-secretsmanager-access-r"
    path   = "/"
    policy = "${data.aws_iam_policy_document.secretsmanager-access-r.json}"
}

resource "aws_iam_role_policy_attachment" "s3-access-rw" {
    role       = "${aws_iam_role.lambda_exec_role.name}"
    policy_arn = "${aws_iam_policy.s3-access-rw.arn}"
}

resource "aws_iam_role_policy_attachment" "dynamo-access-rw" {
    role       = "${aws_iam_role.lambda_exec_role.name}"
    policy_arn = "${aws_iam_policy.dynamo-access-rw.arn}"
}

resource "aws_iam_role_policy_attachment" "secretsmanager-access-r" {
    role       = "${aws_iam_role.lambda_exec_role.name}"
    policy_arn = "${aws_iam_policy.secretsmanager-access-r.arn}"
}