# Step 1
# Description: Creation and configuration of a “master” instance of a web application.
# Defining ec2

# Get most recent Amazon ami
data "aws_ami" "most_recent_amazon_ami" {
  most_recent      = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023*x86_64"]
  }

}

# Ec2 instance to be used as template
resource "aws_instance" "mainInstance" {
    ami = data.aws_ami.most_recent_amazon_ami.id
    instance_type = "t2.nano"
    subnet_id = module.vpc.public_subnets[0]
    vpc_security_group_ids = [aws_security_group.web_server_sg.id]

    tags = {
        Name = "mainInstance"
    }
}


