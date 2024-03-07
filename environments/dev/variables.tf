variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "jenkins_eip_id" {
  type = string
}

variable "jenkins_ami" {
  type = string
}

variable "jenkins_subnet_id" {
  type = string
}

variable "jenkins_vpc_security_group_id" {
  type = string
}

variable "bastion_ami" {
  type = string
}

variable "grafana_adminPassword" {
  type = string
}
variable "grafana_adminUser" {
  type = string
}