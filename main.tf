provider "aws" {
  region  = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.30.0"
    }
  }
}

resource "aws_db_instance" "example_rds" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "123456789"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "RDS Security Group"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Uygun güvenlik politikasına göre ayarlayın
  }
}
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "EC2 Security Group"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Uygun güvenlik politikasına göre ayarlayın
  }
}

output "rds_endpoint" {
  value = aws_db_instance.example_rds.endpoint
}

resource "aws_instance" "example_ec2" {
  depends_on = [aws_db_instance.example_rds]
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  key_name = "firstkey"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = <<-EOF
              #! /bin/bash -x
              yum update -y
              yum install python3 -y
              yum install python-pip -y
              pip3 install Flask==2.3.3
              pip3 install Flask-MySql
              pip3 install boto3
              yum install git -y
              yum install -y mysql
              mysql -h aws_db_instance.example_rds.endpoint -u admin -p 123456789 -e "SHOW DATABASES;"
              TOKEN="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" 
              cd /home/ec2-user
              git clone https://$TOKEN@github.com/Emrkts/Phonebook-Web-App.git
              python3 /home/ec2-user/Phonebook-Web-App/phonebook-app.py
      EOF

}