# Creating S3 bucket to store csv files
resource "aws_s3_bucket" "my_bucket" {
  bucket = "finaltaskbucket2"
  force_destroy = true
}

# IAM Role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambdarole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda to access S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_policy"
  description = "Allows Lambda to interact with S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:HeadObject"  # Adding permission for the HeadObject action
      ]
      Resource  = [
        "${aws_s3_bucket.my_bucket.arn}/*",
        "${aws_s3_bucket.my_bucket.arn}"
      ]
    }]
  })
}

# Attach IAM policy to Lambda role
resource "aws_iam_policy_attachment" "lambda_s3_policy_attachment" {
  name       = "lambda_s3_policy_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}


#policy to invoke lambda
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name   = "lambda_custom_policy"
  role   = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:*",
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "*"
    }
  ]
}
EOF
}

#Attach policies to Lambda execution role, if needed
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# IAM Policy for DynamoDB PutItem operation
resource "aws_iam_policy" "dynamodb_putitem_policy" {
  name        = "dynamodb_putitem_policy"
  description = "Allows PutItem operation on DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:PutItem"
      Resource = aws_dynamodb_table.my_table.arn
    }]
  })
}

# Attach IAM policy to Lambda role
resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_putitem_policy.arn
}
#SNS Policy
resource "aws_iam_role_policy_attachment" "sns_managed_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"  
}



#Creating log group for the Lambda function
resource "aws_cloudwatch_log_group" "upload_lambda_logs" {
  name              = "/aws/lambda/upload-file"
  retention_in_days = 30 # Adjust retention period as needed
}

# Creating log group for the update-file Lambda function
resource "aws_cloudwatch_log_group" "update_lambda_logs" {
  name              = "/aws/lambda/update-file"
  retention_in_days = 30 # Adjust retention period as needed
}

#Creating lambda to upload raw file
resource "aws_lambda_function" "upload" {
    function_name = "upload-file"
    role = aws_iam_role.lambda_role.arn
    image_uri = "934036565719.dkr.ecr.us-east-1.amazonaws.com/upload:latest"
    package_type = "Image"
}


#Creating lambda to upload modified file
resource "aws_lambda_function" "update" {
    function_name = "update-file"
    role = aws_iam_role.lambda_role.arn
    image_uri = "934036565719.dkr.ecr.us-east-1.amazonaws.com/update:latest"
    package_type = "Image"
  
}

resource "aws_api_gateway_rest_api" "upload_api" {
  name        = "upload-api"
  description = "API to apload csv file from local to s3"
}

#Creating resource for the api
resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  parent_id   = aws_api_gateway_rest_api.upload_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.upload_api.id
  resource_id   = aws_api_gateway_resource.upload_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create Lambda integration with API 
resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id             = aws_api_gateway_rest_api.upload_api.id
  resource_id             = aws_api_gateway_resource.upload_resource.id
  http_method             = aws_api_gateway_method.upload_method.http_method
  integration_http_method = "POST"  # Adjusted to GET for a GET request
  type                    = "AWS_PROXY"

  uri = aws_lambda_function.upload.invoke_arn
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "upload_deployment" {
  depends_on  = [aws_api_gateway_integration.upload_integration]
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  stage_name  = "prod"
}

#######################################################
#Creating resource for the api
resource "aws_api_gateway_resource" "update_resource" {
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  parent_id   = aws_api_gateway_rest_api.upload_api.root_resource_id
  path_part   = "update"
}

resource "aws_api_gateway_method" "update_method" {
  rest_api_id   = aws_api_gateway_rest_api.upload_api.id
  resource_id   = aws_api_gateway_resource.update_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create Lambda integration with API 
resource "aws_api_gateway_integration" "update_integration" {
  rest_api_id             = aws_api_gateway_rest_api.upload_api.id
  resource_id             = aws_api_gateway_resource.update_resource.id
  http_method             = aws_api_gateway_method.update_method.http_method
  integration_http_method = "POST"  # Adjusted to GET for a GET request
  type                    = "AWS_PROXY"

  uri = aws_lambda_function.update.invoke_arn
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "update_deployment" {
  depends_on  = [aws_api_gateway_integration.update_integration]
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  stage_name  = "prod"
}

# Grant API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gateway_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:934036565719:enqld4tjda/*/POST/upload"
}

# Grant API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:934036565719:enqld4tjda/*/POST/update"
}
# Creating Lambda for sanity analysis
####################################################################

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "pythoncode.py"
  output_path = "Outputs/lambda.zip"
}

resource "aws_lambda_function" "example_lambda" {
  function_name = "Sanity-Analysis"
  handler       = "pythoncode.lambda_handler"
  runtime       = "python3.8"
  filename      = "Outputs/lambda.zip" 
  role          = aws_iam_role.lambda_role.arn
}
# Lambda for raw Sanity
data "archive_file" "raw" {
  type        = "zip"
  source_file = "code.py"
  output_path = "Output/lambda.zip"
}

resource "aws_lambda_function" "raw_lambda" {
  function_name = "RawSanity"
  handler       = "code.lambda_handler"
  runtime       = "python3.8"
  filename      = "Output/lambda.zip" 
  role          = aws_iam_role.lambda_role.arn
}

data "archive_file" "readfile" {
  type        = "zip"
  source_file = "choice.py"
  output_path = "Outpu/lambda.zip"
}

resource "aws_lambda_function" "extract" {
  function_name = "Extractkey"
  handler       = "choice.lambda_handler"
  runtime       = "python3.8"
  filename      = "Outpu/lambda.zip" 
  role          = aws_iam_role.lambda_role.arn
}
