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

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${module.eks.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
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
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
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

      min_size     = 2
      max_size     = 5
      desired_size = 3

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