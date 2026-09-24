data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

data "aws_route53_zone" "public" {
  count = var.enable_public_edge ? 1 : 0

  name         = format("%s.", var.hosted_zone_name)
  private_zone = false
}

locals {
  name = format("%s-%s", var.project_name, var.environment)
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}
