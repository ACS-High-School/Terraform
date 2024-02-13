terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {}

module "b3o_repository" {
  source               = "../../modules/ecr"
  repository_names     = ["frontend", "backend"]
  image_tag_mutability = "IMMUTABLE"
  encryption_type      = "AES256"
  scan_on_push         = true
}
