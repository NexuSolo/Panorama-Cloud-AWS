terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-west-3"
  access_key = # Remplacez <ACCESS_KEY> par votre access key
  secret_key = # Remplace <SECRET_KEY> par votre secret key
}

resource "aws_instance" "app_server" {
  count = 2
  ami           = "ami-00ac45f3035ff009e"
  instance_type = "t2.micro"
  key_name      = "myKey"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_tcp_2377.id, aws_security_group.allow_tcp_7946.id, aws_security_group.allow_udp_7946.id, aws_security_group.allow_udp_4789.id]

  tags = {
    Name = "PanoramaWebM1Efrei"
  }

}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "vpc-04b916865a88c79f9"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_tcp_2377" {
    name        = "allow_tcp_2377"
    description = "Allow Ansible inbound traffic"

    #ports TCP 2377
    ingress {
        from_port   = 2377
        to_port     = 2377
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}

resource "aws_security_group" "allow_tcp_7946" {
    name        = "allow_tcp_7946"
    description = "Allow Ansible inbound traffic"

    #ports TCP 7946
    ingress {
        from_port   = 7946
        to_port     = 7946
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_udp_7946" {
    name        = "allow_udp_7946"
    description = "Allow Ansible inbound traffic"

    #ports UDP 7946
    ingress {
        from_port   = 7946
        to_port     = 7946
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_udp_4789" {
    name        = "allow_udp_4789"
    description = "Allow Ansible inbound traffic"

    #ports UDP 4789
    ingress {
        from_port   = 4789
        to_port     = 4789
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

output "app_server_public_dns" {
  value = aws_instance.app_server[*].public_dns
}

output "app_server_public_ip" {
  value = aws_instance.app_server[*].public_ip
}