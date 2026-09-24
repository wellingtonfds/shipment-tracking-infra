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

data "aws_eks_cluster_auth" "this" {
  name = module.platform.eks_cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.platform.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.platform.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
