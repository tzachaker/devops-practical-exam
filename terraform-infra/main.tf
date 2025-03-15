# I used Terraform remote execution to automate installation
# I wrote a script that will automatically install Docker after the server starts ---> BONUS

provider "aws" {
  region = "us-east-1" 
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "builder-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "builder_sg" {
  name        = "builder-security-group"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
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

resource "aws_instance" "builder" {
  ami             = "ami-0c55b159cbfafe1f0" 
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.ssh_key.key_name
  security_groups = [aws_security_group.builder_sg.name]

  tags = {
    Name = "builder"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}

output "public_ip" {
  value = aws_instance.builder.public_ip
}
