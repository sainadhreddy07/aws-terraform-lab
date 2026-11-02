
output "vpc_id" {
  value = aws_vpc.lab.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.ec2.id
}

output "instance_id" {
  value = aws_instance.lab.id
}

output "instance_public_ip" {
  value = aws_instance.lab.public_ip
}

output "instance_private_ip" {
  value = aws_instance.lab.private_ip
}

output "ebs_volume_id" {
  value = aws_ebs_volume.data.id
}

# output "internal_nlb_dns" {
#   value = aws_lb.internal.dns_name
# }
