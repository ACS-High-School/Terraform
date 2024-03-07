variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "main_region" {
  type = string
}

variable "grafana_adminPassword" {
  type = string
}
variable "grafana_adminUser" {
  type = string
}

