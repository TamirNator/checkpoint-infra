module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.17.0"

  name       = var.vpc_name
  cidr       = var.vpc_cidr
  azs        = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat_gateway  = true
  single_nat_gateway = true
  map_public_ip_on_launch = true
}
