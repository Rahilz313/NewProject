# Creating S3 bucket to store csv files
resource "aws_s3_bucket" "bucket" {
  bucket = "sanity-check-code"
  force_destroy = true
}
