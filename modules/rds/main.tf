resource "aws_db_instance" "b3o_db" {
  instance_class        = "db.t3.micro"
  storage_type          = "gp2"
  allocated_storage     = 20
  max_allocated_storage = 40

  engine         = "mysql"
  engine_version = "8.0.35"

  identifier = "b3o-db"
  username   = var.db_username
  password   = var.db_password

  port                        = 3306
  multi_az                    = true
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 14
  copy_tags_to_snapshot       = true
  db_subnet_group_name        = var.db_subnet_group_name
  vpc_security_group_ids      = [var.db_sg_id]

  skip_final_snapshot = true
  publicly_accessible = true

  tags = {
    Name = "b3o-DB"
  }
}