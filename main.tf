terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
}

resource "aws_s3_bucket" "test-bucket" {
    bucket = "ylin-test-bucket"
}

resource "aws_vpc" "liny_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "liny_security_group" {
    vpc_id = aws_vpc.liny_vpc.id
    name = " liny security group"
}

resource "aws_security_group_rule" "tls_in" {
    protocol = "tcp"
    security_group_id = aws_security_group.liny_security_group.id
    from_port = 443
    to_port = 443
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
}
