# Create the EC2 Instance using the data source ID
resource "aws_instance" "ubuntu_ec2_instance_terraform" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id                   = aws_subnet.tf_subnet_public.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_https_terraform.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "aws-ec2-instance-terraform"
  }

  user_data = file("${path.module}/setup_nginx.sh")
}


# resource "aws_key_pair" "ssh-key" {
#   key_name   = "ssh-key"
#   public_key = var.ssh_public_key
# }
 
# resource "aws_instance" "my_app" {
#   ami                         = var.instance_ami
#   instance_type               = var.instance_type
#   availability_zone           = var.availability_zone
#   security_groups             = [aws_security_group.my_app.id]
#   associate_public_ip_address = true
#   subnet_id                   = aws_subnet.my_app.id
 
#   key_name = "ssh-key"
 
#   ### Install Docker
#   user_data = <<-EOF
#   #!/bin/bash
#   sudo update -y
#   curl -fsSL https://get.docker.com -o get-docker.sh
#   sudo sh get-docker.sh
#   sudo groupadd docker
#   sudo usermod -aG docker ubuntu
#   newgrp docker
#   sudo timedatectl set-timezone America/New_York
#   EOF
 
#   tags = {
#     Name = "my_app_API"
#   }
# }

/*

Component:
- VPC, like "house": (10.0.0.0/16),The boundary of your private network. ,AWS Cloud
- Internet Gateway, "front door": The bridge between your VPC and the Public Internet. ,Attached to VPC
- Public Subnet, "room": A subset of the VPC IP range (10.0.101.0/24). ,Resides inside VPC
- Route Table, "pathway": "The ""GPS"" that directs traffic from 0.0.0.0/0 to the IGW." ,Linked to VPC
- RT Association,The glue that applies the routing rules to your specific subnet. ,Connects Subnet to RT

*/
# resource "aws_vpc" "terraform_vpc" {
#   cidr_block = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   tags = {
#     Name  = "tf_vpc"
#     Environment = "TF_development_VPC"
#     Owner = "Tatek-Itzhak"
#     Department = "Web Application"
#   }
# }

# Define the Internet Gateway resource and attach it to the VPC
resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "terraform_internet_gateway"
    Environment = "TF_development_internet_gateway"
  }
}

# Public subnet
resource "aws_subnet" "tf_subnet_public" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = true

  # count                   = length(var.public_subnets_cidr)
  # availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name = "terraform_subnet_public"
    Environment = "TF_development_subnet_public"
  }
}


resource "aws_route_table" "terraform_rt_public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name  = "terraform__rt-public"
    Environment = "TF_development_rt_public"
  }
}

#  Associate route tables for subnets
resource "aws_route_table_association" "terraform_rta_public" {
  subnet_id      = aws_subnet.tf_subnet_public.id
  route_table_id = aws_route_table.terraform_rt_public.id
}

resource "aws_security_group" "allow_ssh_http_https_terraform" {
  
  #   vpc_id      = "vpc-0d096b2c1d33a1aba"
  # vpc_id = data.aws_vpc.vpc.id
  vpc_id = var.vpc_id
  name        = "security-group-using-terraform"
  description = "security group using terraform"
  tags = {
    Name = "TF_SG"
  }

  ingress {
    description      = "Allow HTTPS TCP connections"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTP TCP connections"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow SSH connections"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow Public connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

output "ec2_ip_address" {
  value = aws_instance.ubuntu_ec2_instance_terraform.public_ip
}

# Output the Public IPs
/* output "ubuntu_instance_public_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}

# Output VPC CIDR Block
output "vpc_cidr_block" {
  value = data.aws_vpc.default.cidr_block
  description = "The CIDR block of the default VPC"
}

# Output Subnet CIDR Block
output "subnet_cidr_block" {
  value = data.aws_subnet.default.cidr_block
  description = "The CIDR block of the default subnet"
} */


resource "null_resource" "create_file_localy" {
  provisioner "local-exec" {

    # command = "echo 'Automate AWS Infra Deployment ${join(", ", data.aws_subnets.example.ids)} using Terraform...' > hello.txt"
    # command = "echo -e 'Automate AWS Infra Deployment\n${join(", ", data.aws_subnets.example.ids)}\nusing Terraform and GitHub Actions Workflows' > hello.txt"
    command = <<EOT
                  echo 'Target Region: ${data.aws_region.current.id} \n
  Target ec2_ip_address: ${aws_instance.ubuntu_ec2_instance_terraform.public_ip}\n' > aws_provision_info.txt
                  echo 'Target ec2_ip_address: ${aws_instance.ubuntu_ec2_instance_terraform.public_ip}' > ec2_ip_address.txt
              EOT
  }
}

