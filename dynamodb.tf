# Creating Dynamo Db table
resource "aws_dynamodb_table" "my_table" {
  name           = "table1"
  billing_mode   = "PAY_PER_REQUEST"  
  hash_key       = "ID"
  attribute {
    name = "ID"
    type = "S"  # S represents string type
  }
}
