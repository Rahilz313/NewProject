resource "aws_iam_role" "step_functions_role" {
  name = "step_functions_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_role_policy" {
  name   = "lambda_invoke_policy"
  role   = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:us-east-1:934036565719:function:extractkey"
    }]
  })
}




resource "aws_iam_role_policy_attachment" "step_functions_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_sfn_state_machine" "trigger_lambda" {
  name       = "TriggerLambdaStateMachine"
  role_arn   = aws_iam_role.step_functions_role.arn
  definition = jsonencode({
    "StartAt": "ExtractS3Event",
    "States": {
      "ExtractS3Event": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:Extractkey",
        "Next": "CheckFileType",
        "ResultPath": "$.s3EventOutput"
      },
      "CheckFileType": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.s3EventOutput.newestFileName",
            "StringEquals": "uploaded_file.csv",
            "Next": "SanityforRawData"
          },
          {
            "Variable": "$.s3EventOutput.newestFileName",
            "StringEquals": "updated_file.csv",
            "Next": "SanityCheck"
          }
        ],
        "Default": "EndState"
      },
      "SanityforRawData": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:RawSanity",
        "Next": "LoadtoRDS"
      },
      "LoadtoRDS": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:Loaddata",
        "Retry": [
          {
            "ErrorEquals": ["States.TaskFailed"],
            "IntervalSeconds": 10,
            "MaxAttempts": 2
          }
        ],
        "Next": "notification"  // New Lambda state added here
      },
      "notification": {  // New Lambda state definition
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:testnotification",
        "End": true
      },
      "SanityCheck": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:Sanity-Analysis",
        "Next": "Loadmodifieddata"
      },
      "Loadmodifieddata": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:loadupdated-data",
        "Retry": [
          {
            "ErrorEquals": ["States.TaskFailed"],
            "IntervalSeconds": 10,
            "MaxAttempts": 2
          }
        ],
        "ResultPath": "$.LoadModifiedDataOutput",
        "Next": "notifyuser" 
      },
      "notifyuser": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:us-east-1:934036565719:function:testnotification",
        "InputPath": "$.LoadModifiedDataOutput",
        "End": true
      },
      "EndState": {
        "Type": "Pass",
        "End": true
      }
    }
  })
}







resource "aws_lambda_permission" "event_invoke_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:934036565719:function:start-execution"
  principal     = "events.amazonaws.com"
}


