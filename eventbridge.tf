# CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "s3_object_created_rule" {
  name        = "s3_object_created_rule"
  description = "Trigger Step Function when an object is created in finaltaskbucket2"
  
  event_pattern = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["finaltaskbucket2"]
    }
  }
}
PATTERN
}

# CloudWatch Event Target (to trigger Lambda function or Step Function)
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_object_created_rule.name  # Use the correct CloudWatch Event Rule name
  target_id = "start-execution"
  arn       = "arn:aws:lambda:us-east-1:934036565719:function:start-execution"
}

# Lambda Permission for CloudWatch Events to invoke Lambda function
resource "aws_lambda_permission" "event_invoke_lambda1" {
  statement_id  = "AllowExecution1"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:934036565719:function:start-execution"
  principal     = "events.amazonaws.com"
}

##############
# Corrected CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "s3_object_created_rule2" {
  name        = "s3_extract_key"
  description = "Trigger Step Function when an object is created in finaltaskbucket2"
  
  event_pattern = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["finaltaskbucket2"]
    }
  }
}
PATTERN
}

# Corrected CloudWatch Event Target (to trigger Lambda function or Step Function)
resource "aws_cloudwatch_event_target" "lambda_target2" {
  rule      = aws_cloudwatch_event_rule.s3_object_created_rule2.name  # Correctly reference the CloudWatch Event Rule name
  target_id = "ExtractKey"
  arn       = "arn:aws:lambda:us-east-1:934036565719:function:Extractkey"  # Corrected Lambda function ARN
}

# Corrected Lambda Permission for CloudWatch Events to invoke Lambda function
resource "aws_lambda_permission" "event_invoke_lambda2" {
  statement_id  = "AllowExecution2"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:934036565719:function:Extractkey"
  principal     = "events.amazonaws.com"
}
