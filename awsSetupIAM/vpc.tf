#========================== AMI VPC =============================
# Define a vpc
resource "aws_vpc" "ami_vpc" {
  cidr_block = "${var.ami_network_cidr}"
  tags {
    Name = "${var.ami_vpc}"
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "ami_ig" {
  vpc_id = "${aws_vpc.ami_vpc.id}"
  tags {
    Name = "ami_ig"
  }
}

# Public subnet
resource "aws_subnet" "ami_public_sn" {
  vpc_id = "${aws_vpc.ami_vpc.id}"
  cidr_block = "${var.ami_public_cidr}"
  availability_zone = "${lookup(var.availability_zone, var.region)}"
  tags {
    Name = "ami_public_sn"
  }
}

# Routing table for public subnet
resource "aws_route_table" "ami_public_sn_rt" {
  vpc_id = "${aws_vpc.ami_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ami_ig.id}"
  }
  tags {
    Name = "ami_public_sn_rt"
  }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "ami_public_sn_rt_assn" {
  subnet_id = "${aws_subnet.ami_public_sn.id}"
  route_table_id = "${aws_route_table.ami_public_sn_rt.id}"
}

# ECS Instance Security group
resource "aws_security_group" "ami_public_sg" {
  name = "ami_pubic_sg"
  description = "AMI public access security group"
  vpc_id = "${aws_vpc.ami_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = [
      "${var.ami_public_cidr}"]
  }

  egress {
    # allow all traffic to private SN
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags {
    Name = "ami_pubic_sg"
  }
}
