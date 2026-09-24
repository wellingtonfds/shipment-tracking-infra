resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.4.2"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.platform.eks_cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.platform.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [module.platform]
}

resource "helm_release" "tracking_baseline" {
  name  = "tracking-baseline"
  chart = "${path.module}/../kubernetes/tracking-baseline"
  # The release record lives in default because the chart itself creates tracking.
  namespace = "default"

  set {
    name  = "namespace"
    value = "tracking"
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "backendSecretArn"
    value = module.platform.backend_runtime_secret_arn
  }

  set {
    name  = "targetGroupArn"
    value = module.platform.application_target_group_arn
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    module.platform
  ]
}
