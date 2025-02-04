region = "eu-west-1"
vpc_cidr = "10.0.0.0/24"
public_subnets  = ["10.0.0.0/26", "10.0.0.64/26"]
private_subnets = ["10.0.0.128/26", "10.0.0.192/26"]
azs        = ["eu-west-1a", "eu-west-1b"]
vpc_name   = "tamir-vpc"
cluster_name = "dev"