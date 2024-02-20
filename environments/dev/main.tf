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

module "b3o_vpc" {
  source   = "../../modules/vpc"
  vpc_name = "b3o"
}

module "b3o_db" {
  source = "../../modules/rds"

  db_username          = var.db_username
  db_password          = var.db_password
  ap_private_subnet_a  = module.b3o_vpc.database_subnets_cidr_blocks[0]
  ap_private_subnet_c  = module.b3o_vpc.database_subnets_cidr_blocks[1]
  db_subnet_group_name = module.b3o_vpc.db_subnet_group_name
  db_vpc_id            = module.b3o_vpc.vpc_id
}
