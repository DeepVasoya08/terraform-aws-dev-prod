# 🚀 Terraform AWS Infrastructure Tutorial

> **A beginner-friendly guide to deploying AWS infrastructure using Terraform**

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

## 📋 Table of Contents

- [Overview](#-overview)
- [Project Structure](#-project-structure)
- [What This Project Creates](#-what-this-project-creates)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Understanding the Code](#-understanding-the-code)
- [Environments](#-environments)
- [Security Considerations](#-security-considerations)
- [Common Commands](#-common-commands)
- [Troubleshooting](#-troubleshooting)
- [Cost Considerations](#-cost-considerations)
- [Next Steps](#-next-steps)

## 🎯 Overview

This project demonstrates how to use **Terraform** (Infrastructure as Code) to create AWS resources across different environments. It's perfect for beginners who want to learn:

- How to structure Terraform projects
- Managing multiple environments (dev/prod)
- Creating VPCs, EC2 instances, and RDS databases
- Best practices for AWS infrastructure

## 📁 Project Structure

```
terraform-tute/
├── 📄 main.tf              # Main configuration & provider setup
├── 📁 dev/                 # Development environment
│   └── main.tf            # Dev-specific resources
├── 📁 prod/               # Production environment
│   └── main.tf            # Prod-specific resources
├── 📄 .gitignore          # Git ignore rules for Terraform
├── 📄 ec2-amis.txt        # Reference for AWS AMI IDs
└── 📄 README.md           # This file!
```

## 🏗️ What This Project Creates

### 🔧 Development Environment (`dev/`)
- **EC2 Instance**: `t2.micro` (Free Tier eligible)
- **Security Group**: SSH (22), HTTP (80), HTTPS (443), MySQL (3306)
- **Storage**: 30GB GP3 volume

### 🏭 Production Environment (`prod/`)
- **EC2 Instance**: `t3.medium` (More powerful)
- **VPC Infrastructure**: Custom VPC with public subnets
- **RDS MySQL Database**: `db.t3.micro` with 20GB storage
- **High Availability**: Multi-AZ setup
- **Security Groups**: Separate for web and database

### 🔑 Shared Resources
- **SSH Key Pair**: Auto-generated for secure access
- **Security Groups**: Configured for web traffic

## ✅ Prerequisites

Before you start, make sure you have:

### 1. 🔧 Tools Installed
```bash
# Install Terraform
# Visit: https://developer.hashicorp.com/terraform/downloads

# Install AWS CLI
# Visit: https://aws.amazon.com/cli/

# Verify installations
terraform --version
aws --version
```

### 2. 🔐 AWS Account Setup
1. Create an [AWS Account](https://aws.amazon.com/)
2. Create an IAM user with **programmatic access**
3. Attach the `PowerUserAccess` policy (or create custom policy)
4. Save your **Access Key ID** and **Secret Access Key**

### 3. 🌍 Configure AWS Credentials

**Option A: Environment Variables (Recommended)**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"
```

**Option B: AWS CLI Profile**
```bash
aws configure
# Enter your credentials when prompted
```

**Option C: Update main.tf (Not Recommended for Production)**
```hcl
provider "aws" {
  region     = "ap-south-1"
  access_key = "your-access-key"        # ⚠️ Never commit real keys!
  secret_key = "your-secret-key"        # ⚠️ Never commit real keys!
}
```

## 🚀 Quick Start

### Step 1: Clone and Navigate
```bash
git clone https://github.com/DeepVasoya08/terraform-aws-dev-prod.git
cd terraform-aws-dev-prod
```

### Step 2: Initialize Terraform
```bash
terraform init
```
This downloads the AWS provider and sets up your workspace.

### Step 3: Plan Your Infrastructure
```bash
terraform plan
```
This shows you what Terraform will create (like a preview).

### Step 4: Deploy Everything
```bash
terraform apply
```
Type `yes` when prompted. This creates all your AWS resources!

### Step 5: Get Your Connection Info
After deployment, Terraform will output important information:
```
Outputs:

key_created = "New key created and saved to ./terraform-key.pem"
rds_endpoint = "prod-mysql-instance.xyz.ap-south-1.rds.amazonaws.com"
rds_password = "your-generated-password"
mysql_connection_string = "mysql -h prod-mysql-instance.xyz.ap-south-1.rds.amazonaws.com -P 3306 -u admin -p"
```

## 🧠 Understanding the Code

### 🔧 Main Configuration (`main.tf`)

**Provider Setup**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"          # Use AWS provider version 5.x
    }
  }
}
```

**Auto-Generated SSH Keys**
- Creates SSH key pair automatically
- Saves private key as `terraform-key.pem`
- Uses existing keys if already present

**Module Structure**
```hcl
module "dev" {
  source   = "./dev"              # Points to dev/ folder
  key_name = aws_key_pair.terraform_key.key_name
}
```

### 🛡️ Security Groups

**Development**: Open for testing
- SSH (22), HTTP (80), HTTPS (443), MySQL (3306)

**Production**: More restrictive
- Separate security groups for web and database
- Database only accessible from web servers

## 🌍 Environments

### 🔧 Development Environment
**Purpose**: Testing and development
- **Instance**: `t2.micro` (Free Tier)
- **Network**: Default VPC
- **Database**: Shared with prod (for demo)

### 🏭 Production Environment
**Purpose**: Live applications
- **Instance**: `t3.medium` (Better performance)
- **Network**: Custom VPC with proper subnetting
- **Database**: Dedicated RDS MySQL instance
- **Security**: Enhanced security groups

## 🔒 Security Considerations

### ⚠️ Current Setup (Demo/Learning)
- MySQL database is **publicly accessible**
- SSH access from **anywhere** (0.0.0.0/0)
- Passwords stored in Terraform state

### 🛡️ For Production Use
```hcl
# Restrict SSH access to your IP
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]    # Replace with your IP
}

# Use private subnets for databases
resource "aws_subnet" "private_subnet" {
  # ... private subnet configuration
  map_public_ip_on_launch = false
}

# Use AWS Secrets Manager for passwords
resource "aws_secretsmanager_secret" "db_password" {
  name = "rds-password"
}
```

## 🔧 Common Commands

### 📋 Planning and Applying
```bash
# See what will be created/changed
terraform plan

# Apply changes
terraform apply

# Apply without confirmation prompt
terraform apply -auto-approve

# Apply only specific resources
terraform apply -target=module.dev
```

### 📊 Inspecting Infrastructure
```bash
# Show current state
terraform show

# List all resources
terraform state list

# Show outputs
terraform output

# Show specific output
terraform output rds_endpoint
```

### 🧹 Destroying Infrastructure
```bash
# Preview destruction
terraform plan -destroy

# Destroy everything
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resources
terraform destroy -target=aws_db_instance.prod
```

### 🔄 State Management
```bash
# Refresh state from AWS
terraform refresh

# Import existing AWS resource
terraform import aws_instance.example i-1234567890abcdef0
```

## 🐛 Troubleshooting

### ❌ Common Errors

**Error: "No valid credential sources found"**
```bash
# Solution: Configure AWS credentials
aws configure
# OR
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

**Error: "InvalidKeyPair.NotFound"**
```bash
# Solution: The SSH key doesn't exist in AWS
terraform destroy
terraform apply    # This will recreate the key
```

**Error: "Resource already exists"**
```bash
# Solution: Import existing resource or use different name
terraform import aws_instance.example i-1234567890abcdef0
```

**Error: "Insufficient capacity"**
```bash
# Solution: Try different availability zone
availability_zone = "ap-south-1b"    # Instead of ap-south-1a
```

### 🔍 Debugging Tips

1. **Check AWS Console**: Verify resources in AWS web console
2. **Use Terraform Graph**: `terraform graph | dot -Tpng > graph.png`
3. **Enable Debug Logging**: `TF_LOG=DEBUG terraform apply`
4. **Validate Configuration**: `terraform validate`

## 💰 Cost Considerations

### 💚 Free Tier Resources
- **EC2 t2.micro**: 750 hours/month
- **RDS db.t3.micro**: 750 hours/month
- **EBS Storage**: 30GB/month
- **Data Transfer**: 1GB/month

### 💰 Paid Resources
- **EC2 t3.medium**: ~$30/month
- **RDS Storage**: ~$2.30/month for 20GB
- **Data Transfer**: $0.09/GB after free tier

### 💡 Cost Saving Tips
```bash
# Use smaller instances for testing
instance_class = "db.t3.micro"    # Instead of db.t3.small

# Stop instances when not needed
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Use Spot Instances for dev
resource "aws_spot_instance_request" "dev" {
  # ... spot instance configuration
}
```

## 🎓 Next Steps

### 📚 Learn More
1. **Terraform Modules**: Create reusable components
2. **Remote State**: Store state in S3 bucket
3. **CI/CD Integration**: Automate with GitHub Actions
4. **Monitoring**: Add CloudWatch alarms
5. **Auto Scaling**: Implement auto-scaling groups

### 🔨 Enhance This Project
```hcl
# Add Application Load Balancer
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  # ... more configuration
}

# Add Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  vpc_zone_identifier = [aws_subnet.public.id]
  min_size            = 1
  max_size            = 3
  # ... more configuration
}

# Add CloudWatch Monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  # ... more configuration
}
```

### 📖 Additional Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**Happy Terraforming! 🚀**

> Remember: Always run `terraform destroy` when you're done experimenting to avoid unexpected charges!