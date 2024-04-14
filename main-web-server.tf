# Step 1
# Description: Creation and configuration of a “master” instance of a web application.
# Defining ec2

# Get most recent Amazon ami
data "aws_ami" "most_recent_ami" {
  most_recent      = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023*x86_64"]
  }

}

