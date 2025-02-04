variable "region" {
  description = "AWS region"
  type = string
}

variable "cluster_name" {
  description = "EKS cluster name"
}

variable "vpc_name" {
  description = "AWS VPC Name"
}

variable "public_subnets" {
  description = "VPC Public Subnet CIDR"
}

variable "private_subnets" {
  description = "VPC Private Subnet CIDR"
}

variable "azs" {
  description = "VPC Availablilty Zones"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}