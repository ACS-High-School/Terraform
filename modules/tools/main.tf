provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

#현재 계정 ID를 가져오기 위한 데이터 소스 선언
data "aws_caller_identity" "current" {}

# Fetch EKS Cluster Details
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

locals {
  oidc_issuer_url   = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_url}"
}


module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = var.main_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.main_region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
}

resource "kubernetes_storage_class" "monitoring_storage_class" {
  metadata {
    name = "monitoring-storage-class"
  }
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type = "gp2"
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_adminPassword
  }

  set {
    name  = "grafana.adminUser"
    value = var.grafana_adminUser
  }
}

resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "elasticsearch"
  namespace        = "efk"
  create_namespace = true

  set {
    name  = "volumeClaimTemplate.storageClassName"
    value = "monitoring-storage-class"
  }

  set {
    name  = "global.storageClass"
    value = "monitoring-storage-class"
  }

  set {
    name  = "master.replicas"
    value = "1"
  }

  set {
    name  = "master.persistence.enabled"
    value = "true"
  }

  set {
    name  = "master.persistence.size"
    value = "4Gi"
  }

  set {
    name  = "coordinating.replicas"
    value = "0"
  }

  set {
    name  = "coordinating.persistence.enabled"
    value = "false"
  }

  set {
    name  = "coordinating.persistence.size"
    value = "0Gi"
  }

  set {
    name  = "data.replicas"
    value = "0"
  }

  set {
    name  = "data.persistence.enabled"
    value = "false"
  }

  set {
    name  = "data.persistence.size"
    value = "0Gi"
  }

  set {
    name  = "global.kibanaEnabled"
    value = "true"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
}

resource "kubernetes_namespace" "web" {
  metadata {
    name = "web"
  }
}

resource "kubernetes_namespace" "was" {
  metadata {
    name = "was"
  }
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3_full_access_policy"
  description = "My policy that grants full access to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
  role       = aws_iam_role.s3_access_role.name
}

resource "kubernetes_service_account" "s3_access_sa_web" {
  metadata {
    name      = "s3-access-sa-web"
    namespace = "web"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_access_role.arn
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_service_account" "s3_access_sa_was" {
  metadata {
    name      = "s3-access-sa-was"
    namespace = "was"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_access_role.arn
    }
  }
  automount_service_account_token = true
}
