resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.jenkins_server.id
  allocation_id = var.jenkins_eip_id
}


resource "aws_instance" "jenkins_server" {
  ami           = var.jenkins_ami
  instance_type = "t3.small"
  key_name      = "B30"
  subnet_id     = var.jenkins_subnet_id

  vpc_security_group_ids = [var.jenkins_vpc_security_group_id]

  root_block_device {
    volume_size = 15
  }

  tags = {
    Name = "B3o_Jenkins"
  }
}