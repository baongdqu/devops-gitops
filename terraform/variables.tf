variable "aws_region" {
  description = "AWS Region deploy hạ tầng"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Môi trường (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "IP CIDR được phép SSH vào server (Nên set IP cá nhân)"
  type        = string
  default     = "0.0.0.0/0"
}
