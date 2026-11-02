variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "availability_zone" {
  type    = string
  default = "ap-south-1a"
}

variable "name_prefix" {
  type    = string
  default = "aws-lab"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = "terraform-lab-key"
}
