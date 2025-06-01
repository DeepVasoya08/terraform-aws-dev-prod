variable "key_name" {
  description = "The key pair name to use for the instances"
  type        = string
}

# Generate a secure random password for RDS
resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a security group for the prod environment
resource "aws_security_group" "prod_web_sg" {
  name        = "prod-web-sg"
  description = "Security group for production web server with SSH, HTTP, and HTTPS"

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

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "prod-web-security-group"
  }
}

# prod instance
resource "aws_instance" "prod-backend-terra" {
  ami           = "ami-0af9569868786b23a"
  instance_type = "t3.medium"
  key_name      = var.key_name

  # Use the security group we define below
  vpc_security_group_ids = [aws_security_group.prod_web_sg.id]

  tags = {
    Name = "prod-backend-terra"
  }
}


# VPC for RDS with MySQL public access
resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds-igw"
  }
}

# Public Subnets for RDS (in different AZs for high availability)
resource "aws_subnet" "rds_public_subnet_1" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "rds-public-subnet-1"
  }
}

resource "aws_subnet" "rds_public_subnet_2" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "rds-public-subnet-2"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "rds_public_rt" {
  vpc_id = aws_vpc.rds_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_igw.id
  }

  tags = {
    Name = "rds-public-route-table"
  }
}

# Associate Route Table with Public Subnets
resource "aws_route_table_association" "rds_public_rta_1" {
  subnet_id      = aws_subnet.rds_public_subnet_1.id
  route_table_id = aws_route_table.rds_public_rt.id
}

resource "aws_route_table_association" "rds_public_rta_2" {
  subnet_id      = aws_subnet.rds_public_subnet_2.id
  route_table_id = aws_route_table.rds_public_rt.id
}

# Security Group for RDS MySQL with public access
resource "aws_security_group" "rds_mysql_sg" {
  name        = "rds-mysql-sg"
  description = "Security group for RDS MySQL with public access"
  vpc_id      = aws_vpc.rds_vpc.id

  # MySQL/Aurora port from anywhere (public access)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MySQL public access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "rds-mysql-security-group"
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds_public_subnet_1.id, aws_subnet.rds_public_subnet_2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

# rds mysql
resource "aws_db_instance" "prod" {

  identifier = "prod-mysql-instance"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  # instance_class = "db.t4g.medium"
  instance_class = "db.t3.micro"

  # Storage configuration
  allocated_storage = 20
  storage_type      = "gp3"

  # DB configuration
  db_name  = "prod"
  username = "admin"
  password = random_password.rds_password.result

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_mysql_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = true
  availability_zone      = "ap-south-1a"

  # Other configuration
  backup_retention_period = 7
  storage_encrypted       = true
  deletion_protection     = false
  skip_final_snapshot     = true # To allow easy deletion during testing

  tags = {
    Name        = "prod-mysql-instance"
    Environment = "production"
  }
}


# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.rds_vpc.id
}

output "rds_password" {
  description = "rds password"
  value       = random_password.rds_password.result
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.prod.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.prod.port
}

output "mysql_connection_string" {
  description = "MySQL connection string"
  value       = "mysql -h ${aws_db_instance.prod.endpoint} -P ${aws_db_instance.prod.port} -u admin -p"
}
