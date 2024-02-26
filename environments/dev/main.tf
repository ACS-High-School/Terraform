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
  repository_names     = ["frontend", "backend", "fl"]
  image_tag_mutability = "MUTABLE"
  encryption_type      = "AES256"
  scan_on_push         = true
}

module "b3o_vpc" {
  source   = "../../modules/vpc"
  vpc_name = "b3o"
}

module "b3o_sg" {
  source = "../../modules/security-group"

  main_vpc_id          = module.b3o_vpc.vpc_id
  public_subnet_a      = module.b3o_vpc.public_subnets_cidr_blocks[0]
  public_subnet_c      = module.b3o_vpc.public_subnets_cidr_blocks[1]
  web_private_subnet_a = module.b3o_vpc.private_subnets_cidr_blocks[0]
  web_private_subnet_c = module.b3o_vpc.private_subnets_cidr_blocks[1]
  was_private_subnet_a = module.b3o_vpc.private_subnets_cidr_blocks[2]
  was_private_subnet_c = module.b3o_vpc.private_subnets_cidr_blocks[3]
  db_private_subnet_a  = module.b3o_vpc.database_subnets_cidr_blocks[0]
  db_private_subnet_c  = module.b3o_vpc.database_subnets_cidr_blocks[1]
}

module "b3o_db" {
  source = "../../modules/rds"

  db_username          = var.db_username
  db_password          = var.db_password
  db_subnet_group_name = module.b3o_vpc.db_subnet_group_name
  db_vpc_id            = module.b3o_vpc.vpc_id
  db_sg_id             = module.b3o_sg.db_sg_id
}

module "b3o_ec2" {
  source            = "../../modules/ec2"
  jenkins_eip_id    = var.jenkins_eip_id
  jenkins_ami       = var.jenkins_ami
  jenkins_subnet_id = var.jenkins_subnet_id

  jenkins_vpc_security_group_id = var.jenkins_vpc_security_group_id
  bastion_ami                   = var.bastion_ami
  bastion_subent_id             = module.b3o_vpc.public_subnets[0]
  bastion_vpc_security_group_id = module.b3o_sg.bastion_sg_id
}

module "b3o_eks" {
  source          = "../../modules/eks"
  cluster_name    = "b3o_eks"
  cluster_version = "1.29"
  vpc_id          = module.b3o_vpc.vpc_id
  private_subnets = module.b3o_vpc.private_subnets
  main_region = "ap-northeast-2"
}
