################################################################################
# Data Sources
################################################################################

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "./modules/vpc"

  vpc_name = local.name
  vpc_cidr = local.vpc_cidr
  azs      = local.azs

  tags = local.tags
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "./modules/eks"

  cluster_name       = local.name
  kubernetes_version = local.kubernetes_version
  private_subnets   = module.vpc.private_subnets
  public_subnets    = module.vpc.public_subnets

  instance_types = ["t3.small"]
  capacity_type  = "SPOT"
  desired_size   = 1
  max_size       = 2
  min_size       = 1

  tags = local.tags

  depends_on = [module.vpc]
}

################################################################################
# S3 Module
################################################################################

module "s3" {
  source = "./modules/s3"

  bucket_name       = "my-terraform-bucket-${data.aws_caller_identity.current.account_id}"
  enable_versioning = true
  sse_algorithm     = "AES256"

  tags = local.tags
}
