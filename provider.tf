provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      DataClass   = "confidential"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "public" {
  name         = format("%s.", var.hosted_zone_name)
  private_zone = false
}

locals {
  name = format("%s-%s", var.project_name, var.environment)
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}
