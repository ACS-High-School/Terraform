provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

data "aws_ami" "b3o_eks_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_encryption_config       = {}

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  eks_managed_node_groups = {
    worker = {
      name            = "b3o-worker-ng"
      use_name_prefix = true

      subnet_ids = var.private_subnets

      min_size     = 2
      max_size     = 2
      desired_size = 2

      ami_id                     = data.aws_ami.b3o_eks_ami.id
      enable_bootstrap_user_data = true

      capacity_type = "ON_DEMAND"
      instance_type = ["t3.medium"]

      create_iam_role          = true
      iam_role_name            = "b3o-ng-role"
      iam_role_use_name_prefix = true
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }

    tools = {
      name            = "b3o-tools-ng"
      use_name_prefix = true

      subnet_ids = var.private_subnets

      min_size     = 1
      max_size     = 1
      desired_size = 1

      ami_id                     = data.aws_ami.b3o_eks_ami.id
      enable_bootstrap_user_data = true

      capacity_type = "ON_DEMAND"
      instance_type = ["m5.large"]

      iam_role_name = "b3o-ng-role"
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = var.admin1_userarn
      username = var.admin1_username
      groups   = ["system:masters"]
    },
    {
      userarn  = var.admin2_userarn
      username = var.admin2_username
      groups   = ["system:masters"]
    },
    {
      userarn  = var.admin3_userarn
      username = var.admin3_username
      groups   = ["system:masters"]
    },
    {
      userarn  = var.admin4_userarn
      username = var.admin4_username
      groups   = ["system:masters"]
    },
  ]
}

# 현재 계정 ID를 가져오기 위한 데이터 소스 선언
data "aws_caller_identity" "current" {}

# Fetch EKS Cluster Details
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

locals {
  oidc_issuer_url   = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_url}"
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${module.eks.cluster_name}_eks_lb"
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

// monitoring namespace 추가
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
// prometheus, grafana 배포
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_adminPassword
  }

  set {
    name  = "grafana.adminUser"
    value = var.grafana_adminUser
  }
}
// efk namespace 추가
resource "kubernetes_namespace" "efk" {
  metadata {
    name = "efk"
  }
}

// fluentbit 배포
resource "helm_release" "fluentbit" {
  name       = "fluentbit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "efk"
}