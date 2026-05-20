provider "aws" {
  region = "ap-south-2"
}

# --- VPC ---
resource "aws_vpc" "liberty_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "liberty-vpc" }
}

# --- Subnet ---
resource "aws_subnet" "liberty_subnet" {
  vpc_id                  = aws_vpc.liberty_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-2a"
  tags = { Name = "liberty-subnet" }
}

# --- Internet Gateway + Route Table ---
resource "aws_internet_gateway" "liberty_igw" {
  vpc_id = aws_vpc.liberty_vpc.id
}

resource "aws_route_table" "liberty_rt" {
  vpc_id = aws_vpc.liberty_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.liberty_igw.id
  }
}

resource "aws_route_table_association" "liberty_rta" {
  subnet_id      = aws_subnet.liberty_subnet.id
  route_table_id = aws_route_table.liberty_rt.id
}

# --- Security Group ---
resource "aws_security_group" "liberty_sg" {
  name        = "liberty-sg"
  description = "Allow Liberty console and app access"
  vpc_id      = aws_vpc.liberty_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Liberty Admin Console
  ingress {
    from_port   = 9060
    to_port     = 9060
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Liberty HTTP
  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Liberty HTTPS
  ingress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Controller Node ---
resource "aws_instance" "liberty_controller" {
  ami           = "ami-024ebedf48d280810" # Ubuntu 22.04 LTS in ap-south-2
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.liberty_subnet.id
  vpc_security_group_ids = [aws_security_group.liberty_sg.id]
  key_name      = "libertypocpem"
  tags = { Role = "controller", Name = "liberty-controller" }
}

# --- Member Node ---
resource "aws_instance" "liberty_member" {
  ami           = "ami-024ebedf48d280810"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.liberty_subnet.id
  vpc_security_group_ids = [aws_security_group.liberty_sg.id]
  key_name      = "libertypocpem"
  tags = { Role = "member", Name = "liberty-member" }
}

# --- Outputs ---
output "controller_ip" {
  value = aws_instance.liberty_controller.public_ip
}

output "member_ip" {
  value = aws_instance.liberty_member.public_ip
}

output "liberty_console_url" {
  value = "http://${aws_instance.liberty_controller.public_ip}:9060/ibm/console"
}
