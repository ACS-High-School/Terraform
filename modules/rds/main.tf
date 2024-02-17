resource "aws_security_group" "db_sg" {
    name = "db_sg"
    description = "security group for DB"
    vpc_id = var.db_vpc_id

    ingress {
        description = "MySQL"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [var.ap_private_subnet_a, var.ap_private_subnet_c]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.ap_private_subnet_a, var.ap_private_subnet_c]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "b3o_db_sg"
    }
}

resource "aws_db_instance" "b3o_db" {
    instance_class = "db.t3.micro"          
    storage_type = "gp2"                    
    allocated_storage = 20                  
    max_allocated_storage = 40              

    engine = "mysql"
    engine_version = "8.0.31"               

    identifier = "b3o-db"                 
    username = var.db_username
    password = var.db_password                  

    port = 3306 
    multi_az = true
    allow_major_version_upgrade = true
    auto_minor_version_upgrade = true
    backup_retention_period = 14            
    copy_tags_to_snapshot = true            
    db_subnet_group_name = var.db_subnet_group_name
    vpc_security_group_ids = [aws_security_group.db_sg.id]

    skip_final_snapshot = true
    publicly_accessible = true

    tags = {
        Name = "b3o-DB"
    }
}

resource "aws_db_instance" "replica_b3o_db" {
  instance_class       = "db.t3.micro"
  identifier = "replica-b3o-db" 
  skip_final_snapshot  = true 
  backup_retention_period = 7
  replicate_source_db = aws_db_instance.b3o_db.identifier
}