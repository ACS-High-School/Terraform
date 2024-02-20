resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    description = "security group for BASTION"
    vpc_id = var.main_vpc_id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "b3o_bastion_sg"
    }
  
}

resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    description = "security group for ALB"
    vpc_id = var.main_vpc_id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "b3o_alb_sg"
    }
}


resource "aws_security_group" "web_sg" {
    name = "web_sg"
    description = "security group for WEB"
    vpc_id = var.main_vpc_id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.public_subnet_a]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ var.public_subnet_a, var.public_subnet_c]
    }

    egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [var.was_private_subnet_a, var.was_private_subnet_c]
    }

    tags = {
        Name = "b3o_web_sg"
  }
}

resource "aws_security_group" "was_sg" {
    name = "was_sg"
    description = "security group for WAS"
    vpc_id = var.main_vpc_id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.public_subnet_a]
    }

    ingress {
        description = "HTTP"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [ var.web_private_subnet_a, var.web_private_subnet_c]
    }

    egress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [var.db_private_subnet_a, var.db_private_subnet_c]
    }

    tags = {
        Name = "b3o_was_sg"
  }
}

resource "aws_security_group" "db_sg" {
    name = "db_sg"
    description = "security group for DB"
    vpc_id = var.main_vpc_id

    ingress {
        description = "MySQL"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [var.was_private_subnet_a, var.was_private_subnet_c]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "b3o_db_sg"
    }
}