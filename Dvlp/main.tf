provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_availability_zones" "available" {}

locals {
  name            = basename(path.cwd)
  cluster_name    = coalesce(var.cluster_name, local.name)
  cluster_version = var.cluster_version
  region          = var.region_name
  vpc_cidr        = var.vpc_cidr
  # env_name        = var.env_name

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    BluePrint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

resource "aws_s3_bucket" "tsp-bucket" {
  bucket = "tsp-${var.env_name}-bucket"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "tsp-StateTable" {
  name           = "tsp-${var.env_name}-StateTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

#---------------------------------------------------------------
# EKS BluePrints
#---------------------------------------------------------------

module "eks_blueprints" {
  source = "../aws"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    t3 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.small"]
      min_size        = 0
      max_size        = 100
      desired_size    = 1
      subnet_ids      = module.vpc.private_subnets
    }
  }

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "../aws/modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  # Add-ons
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = false
  enable_aws_cloudwatch_metrics       = true
  enable_kubecost                     = false
  enable_gatekeeper                   = false

  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "podLabels.prometheus\\.io/scrape",
        value = "true",
        type  = "string",
      }
    ]
  }

  enable_cert_manager = true
  cert_manager_helm_config = {
    set_values = [
      {
        name  = "extraArgs[0]"
        value = "--enable-certificate-owner-ref=false"
      },
    ]
  }
  # TODO - requires dependency on `cert-manager` for namespace
  # enable_cert_manager_csi_driver = true

  #---------------------------------------
  # ENABLE EMR ON EKS
  #---------------------------------------
  enable_emr_on_eks = true
  # emr_on_eks_teams = {
  #   emr-team-a = {
  #     namespace               = "emr-data-team-a"
  #     job_execution_role      = "emr-eks-data-team-a"
  #     additional_iam_policies = []
  #   }
  #   emr-team-b = {
  #     namespace               = "emr-data-team-b"
  #     job_execution_role      = "emr-eks-data-team-b"
  #     additional_iam_policies = []
  #   }
  # }

  tags = local.tags
}

#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}
