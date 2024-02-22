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
variable "bastion_subent_id" {
  type = string
}

variable "bastion_vpc_security_group_id" {
  type = string
}