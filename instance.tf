provider "aws" {
  region = "ap-south-1"
  profile = "shaw"
}

resource "aws_key_pair" "key" {
  key_name   = "task-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAjl4x/ZdCZ1ykOdVNSzR9LcOo4hS1YZlDEOLu2LfX3SvlpxmeBh9HKn2VvEoHHLPoKGHNShtLf74M2J4XF1MKiCSxi5d+UZtv0125F3XqGVymVmKJFlOPvVfZ4tpu5hVWadVLl4IzQbbsnfK5Dy3vYZY/W+j/qv4Ps3QBm3HiRkURFFqxFLOexPMMNq3nk0DLArFv50CA2PpIFYZ+OnW+Uklf+6cpbQyWn3Qk0oZMUk2UxInfiyORLVkl3mU3BUDK9Hq8WUCjf/GB3Q0iGZo1rIIjL8tUdq3nK/9UWyShuWqMYyyW7uZ3ZVOeiBettc+keggulF/eI+apH+JSJfBvsw== rsa-key-20200611"
}


resource "aws_security_group" "swat" {
  name        = "swat"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "vpc-ebe9f483"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
egress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
egress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
   tags = {
    Name = "swat"
  }
}

resource "aws_ebs_volume" "ebsv" {
  availability_zone = aws_instance.inst.availability_zone
  size              = 1

  tags = {
    Name = "volume"
  }
}


resource "aws_volume_attachment" "v_att" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.ebsv.id
  instance_id = aws_instance.inst.id
  force_detach = true

}

resource "aws_instance" "inst" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "task-key"
  security_groups = ["swat"]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/shaurya/Downloads/task-key.pem")
    host     = aws_instance.inst.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "task-os"
  }

}
resource "null_resource" "local1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.inst.public_ip} > publicip.txt"
  	}
}


resource "null_resource" "remote2"  {

depends_on = [
    aws_volume_attachment.v_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/shaurya/Downloads/task-key.pem")
     host     = aws_instance.inst.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdd",
      "sudo mount  /dev/xvdd  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/shauryasharma30/Multicloud.git /var/www/html/"
    ]
  }
}

resource "null_resource" "execution"  {
depends_on = [
    null_resource.remote2,
  ]
	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.inst.public_ip}"
  	}
}



