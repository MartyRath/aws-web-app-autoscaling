variable "instance_name" {
    description = "Name tag of EC2 Instance"
    type        = string
    default     = "NewInstance"
}

variable "ec2_instance_type" {
    description = "AWS EC2 instance type"
    type = string
    default = "t2.nano"
}