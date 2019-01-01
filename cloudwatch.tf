resource "aws_cloudwatch_event_rule" "every_month" {
    name = "every-month"
    description = "Fires on the first of each month at 8am"
    schedule_expression = "cron(0 8 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "run_invoice_me_every_month" {
    rule = "${aws_cloudwatch_event_rule.every_month.name}"
    arn = "${aws_lambda_function.lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_invoice_me" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_month.arn}"
}