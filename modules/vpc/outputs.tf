output "vpc_id" {
  value = module.b3o_vpc.vpc_id
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

output "database_subnets_cidr_blocks" {
  value = module.b3o_vpc.database_subnets_cidr_blocks
}