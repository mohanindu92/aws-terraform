resource "aws_instance" "myec2" {
  ami               = "ami-01816d07b1128cd2d"
  instance_type     = "t2.micro"
  key_name          = "docker-key"
  vpc_security_group_ids = [ "sg-045c43b202e738ee9" ]

  # Connection block for SSH access
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("docker-key.pem")
    host        = self.public_ip
  }

  # Provisioner to copy the local index.html file to the EC2 instance
  provisioner "file" {
    source      = "index.html"        # Local path to your index.html file
    destination = "/tmp/index.html"   # Destination path on the EC2 instance
  }

  # Provisioner to install httpd and move the index.html file to the correct directory
  provisioner "remote-exec" {
    when    = create
    inline = [
      "sudo yum install httpd -y",
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }

  # Provisioner to clean up httpd when destroying the instance
  provisioner "remote-exec" {
    when        = destroy
    on_failure  = continue
    inline = [
      "sudo yum remove -y httpd",
      "echo Httpd has been removed",
      "sleep 5"
    ]
  }
}

# Output the public IP address of the EC2 instance
output "ec2-ip" {
  value = aws_instance.myec2.public_ip
}
