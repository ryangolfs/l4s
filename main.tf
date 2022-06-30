resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.all.id]
  iam_instance_profile   = aws_iam_instance_profile.s3profile.name

  user_data = <<EOF
  #! /bin/bash

  hostnamectl set-hostname log4shell-demo
  yum update -y
  yum install docker git unzip java-1.8.0-openjdk -y
  systemctl start docker
  systemclt enable docker
  # run app
  #sh /tmp/app.sh 
  EOF

  tags = {
    Name = "log4shell-demo"
  }

  provisioner "file" {

    source      = "Dockerfile"
    destination = "/tmp/Dockerfile"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file(var.key.private_key_path)

    }
  }

  provisioner "file" {

    source      = "app.sh"
    destination = "/tmp/app.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file(var.key.private_key_path)
    }

  }

}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key.name
  public_key = var.key.pub
}

resource "aws_security_group" "all" {
  name        = "log4shell all"
  description = "log4shell all"

  ingress {
    description      = "all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "log4shell all"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "l4s-demo-bucket"

  tags = {
    Name = "l4s-demo-bucket"
  }
}

resource "aws_s3_bucket_object" "folders" {
  count  = 5
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
  key    = "data-${count.index}"
  source = "/dev/null"
}

resource "aws_iam_role" "l4s_s3_role" {
  name = "l4s_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "s3policy" {
  name = "s3policy"
  role = aws_iam_role.l4s_s3_role.id

  policy = jsonencode({

    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AccessObject",
        Effect : "Allow",
        Action : [
          "s3:*"
        ],
        Resource : [
          "arn:aws:s3:::l4s-demo-bucket"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "s3profile" {
  name = "s3profile"
  role = aws_iam_role.l4s_s3_role.name
}
