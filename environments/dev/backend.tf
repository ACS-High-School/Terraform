provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    bucket = "b3o-tfstate"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

# S3 bucket for backend
resource "aws_s3_bucket" "tfstate" {
  bucket = "b3o-tfstate"
}

# S3 버킷에서 버전 관리를 제어하기 위한 리소스를 제공합니다.
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id
  # 버킷이 파일을 업데이트 마다 새버전을 생성합니다.
  versioning_configuration {
    status = "Enabled"
  }
}


# DynamoDB for terraform state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

