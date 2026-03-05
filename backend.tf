# # Terraform Backend Configuration
# # Stores state in S3 with DynamoDB locking

# terraform {
#   backend "s3" {
#     bucket               = "bhotel-terraform-state-541645813745"
#     key                  = "terraform.tfstate"
#     region               = "ap-south-1"
#     dynamodb_table       = "bhotel-terraform-locks"
#     encrypt              = true
#     workspace_key_prefix = "env"
#   }
# }
