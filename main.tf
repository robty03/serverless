provider "aws" {
  region = var.region
}

# DynamoDB

resource "aws_dynamodb_table" "todo_table" {
  name         = "todo-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "todo_id"

  attribute {
    name = "todo_id"
    type = "S"
  }
}

# SQS

resource "aws_sqs_queue" "todo_queue" {
  name = "todo-queue"
}

# IAM Role for Lambda

resource "aws_iam_role" "lambda_role" {
  name = "todo-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sqs_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# Lambda submit

resource "aws_lambda_function" "submit" {

  filename         = "lambda/submit.zip"
  function_name    = "todo-submit"
  role             = aws_iam_role.lambda_role.arn
  handler          = "submit.lambda_handler"
  runtime          = "python3.11"

  vpc_config {
    subnet_ids = [
      var.subnet_a,
      var.subnet_b
    ]

    security_group_ids = [
      var.security_group
    ]
  }

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.todo_queue.id
    }
  }
}

# Lambda processor

resource "aws_lambda_function" "processor" {

  filename         = "lambda/processor.zip"
  function_name    = "todo-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "processor.lambda_handler"
  runtime          = "python3.11"

  vpc_config {
    subnet_ids = [
      var.subnet_a,
      var.subnet_b
    ]

    security_group_ids = [
      var.security_group
    ]
  }
}

# SQS trigger

resource "aws_lambda_event_source_mapping" "sqs_trigger" {

  event_source_arn = aws_sqs_queue.todo_queue.arn
  function_name    = aws_lambda_function.processor.arn
}

# EventBridge schedule

resource "aws_cloudwatch_event_rule" "schedule" {

  name                = "todo-cron"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {

  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "todo-submit"
  arn       = aws_lambda_function.submit.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}