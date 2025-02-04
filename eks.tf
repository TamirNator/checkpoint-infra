module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  
  cluster_addons = {
    aws-ebs-csi-driver = {}
    vpc-cni = {}
    coredns = {}
    kube-proxy = {}
    amazon-cloudwatch-observability = {}
    metrics-server = {}
  }
  cluster_enabled_log_types = []
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }
  eks_managed_node_group_defaults = {
    instance_types = ["t2.medium"]
  }
  node_iam_role_additional_policies = {
    EKSPolicy = aws_iam_policy.eks_policy.arn
  }
  access_entries = {
      my_admin_user = {
        principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.id}:user/${data.aws_iam_user.current_user.user_name}"
        type              = "STANDARD"
        kubernetes_groups = ["eks-dev-role"]
      }
    }
  eks_managed_node_groups = {
    main = {
      ami_type      = "AL2_x86_64"
      min_size = 2
      max_size = 10
      desired_size = 2
      iam_role_additional_policies = {
        "EKSPolicy" = aws_iam_policy.eks_policy.arn
      }
    }
  }

  cluster_security_group_additional_rules = {
    hybrid-all = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
      description = "Allow traffic from all"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
  depends_on = [ module.vpc ]
}

data "aws_caller_identity" "current" {}

data "aws_iam_user" "current_user" {
  user_name = "tamirna811"
}