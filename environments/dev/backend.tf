terraform {
  backend "s3" {
    bucket = "b3o-tfstate"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
