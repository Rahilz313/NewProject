
 
resource "aws_db_instance" "example" {
  identifier             = "example-postgres"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = "db.t3.micro"
  username               = "rahil"
  password               = "Rahil1234"
  publicly_accessible    = true
  multi_az               = false
  final_snapshot_identifier = "my-final-snapshot"
  skip_final_snapshot        = false
}
   
 
 
 
# Creating a custom IAM Role
resource "aws_iam_role" "custom_lambda_role" {
  name               = "custom_lambda_role"  # Custom IAM role name
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
 
# Attaching policies to the custom role for insert and read access in RDS
resource "aws_iam_policy_attachment" "rds_insert_read_policy_attachment" {
  name       = "rds-insert-read-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"  
  roles      = [aws_iam_role.custom_lambda_role.name]
}

resource "aws_iam_policy_attachment" "vpc_full_access" {
  name       = "vpc-full-access"
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  roles      = [aws_iam_role.custom_lambda_role.name]
}
 
resource "aws_iam_policy_attachment" "Lambda_basic_execution" {
  name       = "lambda-basic-execution"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.custom_lambda_role.name]
}
 
resource "aws_iam_policy_attachment" "Lambda_vpc_exection_role" {
  name       = "lambda-vpc-execution"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  roles      = [aws_iam_role.custom_lambda_role.name]
}
resource "aws_iam_policy_attachment" "s3_access" {
    name = "s3-policy"
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    roles = [aws_iam_role.custom_lambda_role.name]
  
}
resource "aws_iam_policy_attachment" "sns_access" {
  name       = "sns-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  roles      = [aws_iam_role.custom_lambda_role.name]
}
resource "aws_iam_policy_attachment" "stepfunctions_access" {
  name       = "stepfunctions-policy"
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  roles      = [aws_iam_role.custom_lambda_role.name]
}

 

resource "aws_lambda_function" "my_lambda_function" {
  function_name = "Loaddata"
  role          = aws_iam_role.custom_lambda_role.arn
  image_uri     = "934036565719.dkr.ecr.us-east-1.amazonaws.com/final-task:latest"
  package_type  = "Image"
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "loadupdated-data"
  role          = aws_iam_role.custom_lambda_role.arn
  image_uri     = "934036565719.dkr.ecr.us-east-1.amazonaws.com/modified@sha256:21d6df297b690aa34fe102bf03370ec7f9951ef2f442726cf4e55c87c9fd080c"
  package_type  = "Image"
}
