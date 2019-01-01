data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "src"
    output_path = "lambda.zip"
}


resource "aws_lambda_function" "lambda" {
  role             = "${aws_iam_role.lambda_exec_role.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python2.7"
  filename         = "lambda.zip"
  function_name    = "${var.app_name}"
  source_code_hash = "${base64sha256(file("lambda.zip"))}"
  timeout = 10

  environment {
    variables = {
      harvest_url = "https://api.harvestapp.com/v2/time_entries"
      harvest_id = "",
      invoice_generator_url = "https://invoice-generator.com/",
      s3_bucket = "${aws_s3_bucket.bucket.bucket}"
      slack_message = "Hey, your latest invoice has been generated! "
    }
  }
}