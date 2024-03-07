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
variable "admin1_userarn" {
  type = string
}
variable "admin2_userarn" {
  type = string
}
variable "admin3_userarn" {
  type = string
}
variable "admin4_userarn" {
  type = string
}
variable "admin1_username" {
  type = string
}
variable "admin2_username" {
  type = string
}
variable "admin3_username" {
  type = string
}
variable "admin4_username" {
  type = string
}


