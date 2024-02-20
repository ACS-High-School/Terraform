output "vpc_id" {
  value = module.b3o_vpc.vpc_id
}

output "public_subnets" {
  value = module.b3o_vpc.public_subnets
}

output "private_subnets" {
  value = module.b3o_vpc.private_subnets
}

output "database_subnets" {
  value = module.b3o_vpc.database_subnets
}

output "db_subnet_group_name" {
  value = module.b3o_vpc.database_subnet_group_name
}

output "public_subnets_cidr_blocks" {
  value = module.b3o_vpc.public_subnets_cidr_blocks
}

output "private_subnets_cidr_blocks" {
  value = module.b3o_vpc.private_subnets_cidr_blocks
}

output "database_subnets_cidr_blocks" {
  value = module.b3o_vpc.database_subnets_cidr_blocks
}