# Use to output data such as ec2 public ip or id

output "most_recent_amazon_ami" {
  value = data.aws_ami.most_recent_amazon_ami.id
}