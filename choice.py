import boto3

def lambda_handler(event, context):
    # Initialize the S3 client
    s3 = boto3.client('s3')
    
    # Specify the bucket name
    bucket_name = 'finaltaskbucket2'
    
    try:
        # List objects in the bucket
        response = s3.list_objects_v2(Bucket=bucket_name)
        
        # Extract the newest file name
        newest_file = max(response['Contents'], key=lambda x: x['LastModified'])
        newest_file_name = newest_file['Key']
        
        # Return the newest file name
        return {
            'newestFileName': newest_file_name
        }
    except Exception as e:
        return {
            'errorMessage': str(e)
        }
