# AWS Development Environment
# Phase 1 - Primary deployment target

terraform {
  required_version = ">= 1.6"
  
  # S3 backend for state management
  backend "s3" {
    bucket         = "platform-terraform-state-dev"
    key            = "infrastructure/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "platform-terraform-locks"
    
    # Uncomment after initial setup
    # kms_key_id     = "alias/terraform-state"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Platform    = "campaign-lifecycle"
      CostCenter  = "engineering"
      Owner       = "platform-team"
    }
  }
}

# Provider configuration will be done after cluster creation
provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks_cluster.cluster_id,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks_cluster.cluster_id,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Local variables
locals {
  cluster_name = "platform-dev"
  environment  = "dev"
  region       = var.aws_region
}

# EKS Cluster using cloud-agnostic module
module "eks_cluster" {
  source = "../../../modules/kubernetes-cluster"

  provider_type   = "aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.28"
  region          = local.region
  environment     = local.environment

  # Development node pools - smaller and cheaper
  node_pools = {
    system = {
      count         = 3
      instance_type = "t3.large"      # 2 vCPU, 8 GB RAM
      disk_size_gb  = 100
      labels        = { pool = "system" }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    apps = {
      count         = 3                 # Smaller for dev
      instance_type = "t3.xlarge"       # 4 vCPU, 16 GB RAM
      disk_size_gb  = 150
      labels        = { pool = "apps" }
      taints        = []
    }
    data = {
      count         = 2                 # Minimal for dev
      instance_type = "r6g.large"       # ARM, 2 vCPU, 16 GB RAM
      disk_size_gb  = 300
      labels        = { pool = "data" }
      taints        = []
    }
  }

  enable_autoscaling = true
  autoscaling_config = {
    system = { min_size = 3, max_size = 3 }   # Fixed for system
    apps   = { min_size = 2, max_size = 6 }   # Can scale
    data   = { min_size = 2, max_size = 4 }   # Can scale
  }

  enable_monitoring = true

  tags = {
    Project     = "campaign-lifecycle-platform"
    Environment = "development"
    Team        = "platform-engineering"
  }
}

# Kubernetes namespaces
module "k8s_namespaces" {
  source = "../../../modules/kubernetes-namespaces"
  
  depends_on = [module.eks_cluster]

  namespaces = [
    {
      name   = "platform-system"
      labels = { tier = "system" }
      resource_quotas = {
        requests_cpu    = "10"
        requests_memory = "20Gi"
        limits_cpu      = "20"
        limits_memory   = "40Gi"
      }
    },
    {
      name   = "platform-apps"
      labels = { tier = "apps" }
      resource_quotas = {
        requests_cpu    = "30"
        requests_memory = "60Gi"
        limits_cpu      = "60"
        limits_memory   = "120Gi"
      }
    },
    {
      name   = "platform-data"
      labels = { tier = "data" }
      resource_quotas = {
        requests_cpu    = "20"
        requests_memory = "40Gi"
        limits_cpu      = "40"
        limits_memory   = "80Gi"
      }
    },
    {
      name   = "platform-monitoring"
      labels = { tier = "monitoring" }
      resource_quotas = {
        requests_cpu    = "5"
        requests_memory = "10Gi"
        limits_cpu      = "10"
        limits_memory   = "20Gi"
      }
    }
  ]
}

# Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks_cluster.cluster_ca_certificate
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks_cluster.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_id} --region ${var.aws_region}"
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = <<-EOT
    # Update kubeconfig
    aws eks update-kubeconfig --name ${module.eks_cluster.cluster_id} --region ${var.aws_region}
    
    # Verify connection
    kubectl get nodes
    
    # View namespaces
    kubectl get namespaces
  EOT
}
