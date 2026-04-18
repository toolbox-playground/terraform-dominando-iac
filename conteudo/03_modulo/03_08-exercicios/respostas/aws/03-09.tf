terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example_db" {
  identifier           = "meu-banco-exemplo"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t2.micro"  # Configuração incorreta
  allocated_storage   = 20
  username           = "admin"
  password           = "minhasenhasecreta"
  parameter_group_name = "default.mysql8.0"
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "BancoExemplo"
    Environment = "Dev"
  }
}
