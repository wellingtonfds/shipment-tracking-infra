module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets   = [for index, az in local.azs : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnets  = [for index, az in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 10)]
  database_subnets = [for index, az in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 20)]

  enable_nat_gateway           = true
  single_nat_gateway           = var.single_nat_gateway
  one_nat_gateway_per_az       = !var.single_nat_gateway
  enable_dns_hostnames         = true
  enable_dns_support           = true
  create_database_subnet_group = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
