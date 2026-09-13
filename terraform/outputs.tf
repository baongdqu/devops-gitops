output "vpc_id" {
  description = "ID của VPC vừa tạo"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID của Public Subnet"
  value       = aws_subnet.public_1.id
}

output "security_group_id" {
  description = "ID của Security Group"
  value       = aws_security_group.k8s_node_sg.id
}
