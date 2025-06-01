variable "key_name" {
  description = "The key pair name to use for the instances"
  type        = string
}


# Create a security group for the dev environment
resource "aws_security_group" "dev_web_sg" {
  name        = "dev-web-sg"
  description = "Security group for dev web server with SSH, HTTP, and HTTPS"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # MySQL access from anywhere
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MySQL"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "dev-web-security-group"
  }
}


resource "aws_instance" "dev-backend-terra" {
  ami           = "ami-0af9569868786b23a"
  instance_type = "t2.micro"
  key_name      = var.key_name

  # storage
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp3"
    volume_size = 30
  }

  # Use the security group we define below instead of the default one
  vpc_security_group_ids = [aws_security_group.dev_web_sg.id]

  # tags =
  tags = {
    Name = "dev-backend-terra"
  }
}
