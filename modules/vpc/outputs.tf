output "vpc_id" {
  value = module.b3o_vpc.vpc_id
}

output "private_subnets" {
  value = module.b3o_vpc.private_subnets
}

output "database_subnets" {
  value = module.b3o_vpc.database_subnets
}