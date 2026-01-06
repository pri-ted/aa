# Cloud-Agnostic Kubernetes Cluster Module
# Supports: AWS EKS, GCP GKE, Bare Metal

variable "provider_type" {
  description = "Cloud provider type: aws, gcp, or baremetal"
  type        = string
  validation {
    condition     = contains(["aws", "gcp", "baremetal"], var.provider_type)
    error_message = "Provider must be aws, gcp, or baremetal"
  }
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "region" {
  description = "Cloud provider region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "node_pools" {
  description = "Node pool configurations"
  type = map(object({
    count         = number
    instance_type = string
    disk_size_gb  = number
    labels        = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    system = {
      count         = 3
      instance_type = "t3.large"
      disk_size_gb  = 100
      labels        = { pool = "system" }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    apps = {
      count         = 6
      instance_type = "m5.xlarge"
      disk_size_gb  = 200
      labels        = { pool = "apps" }
      taints        = []
    }
    data = {
      count         = 4
      instance_type = "r5.2xlarge"
      disk_size_gb  = 500
      labels        = { pool = "data" }
      taints        = []
    }
  }
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_config" {
  description = "Autoscaling configuration per node pool"
  type = map(object({
    min_size = number
    max_size = number
  }))
  default = {
    system = { min_size = 3, max_size = 5 }
    apps   = { min_size = 6, max_size = 20 }
    data   = { min_size = 4, max_size = 12 }
  }
}

variable "enable_monitoring" {
  description = "Enable cloud provider monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Conditional module loading based on provider
module "aws_eks" {
  source = "./providers/aws"
  count  = var.provider_type == "aws" ? 1 : 0

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  region              = var.region
  environment         = var.environment
  node_pools          = var.node_pools
  enable_autoscaling  = var.enable_autoscaling
  autoscaling_config  = var.autoscaling_config
  enable_monitoring   = var.enable_monitoring
  tags                = var.tags
}

module "gcp_gke" {
  source = "./providers/gcp"
  count  = var.provider_type == "gcp" ? 1 : 0

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  region              = var.region
  environment         = var.environment
  node_pools          = var.node_pools
  enable_autoscaling  = var.enable_autoscaling
  autoscaling_config  = var.autoscaling_config
  enable_monitoring   = var.enable_monitoring
  tags                = var.tags
}

module "baremetal_k8s" {
  source = "./providers/baremetal"
  count  = var.provider_type == "baremetal" ? 1 : 0

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  environment         = var.environment
  node_pools          = var.node_pools
  tags                = var.tags
}

# Unified outputs regardless of provider
output "cluster_id" {
  description = "Cluster identifier"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].cluster_id :
    var.provider_type == "gcp" ? module.gcp_gke[0].cluster_id :
    module.baremetal_k8s[0].cluster_id
  )
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].cluster_endpoint :
    var.provider_type == "gcp" ? module.gcp_gke[0].cluster_endpoint :
    module.baremetal_k8s[0].cluster_endpoint
  )
  sensitive = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].cluster_ca_certificate :
    var.provider_type == "gcp" ? module.gcp_gke[0].cluster_ca_certificate :
    module.baremetal_k8s[0].cluster_ca_certificate
  )
  sensitive = true
}

output "kubeconfig" {
  description = "Kubeconfig for cluster access"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].kubeconfig :
    var.provider_type == "gcp" ? module.gcp_gke[0].kubeconfig :
    module.baremetal_k8s[0].kubeconfig
  )
  sensitive = true
}

output "node_security_group_id" {
  description = "Security group ID for worker nodes"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].node_security_group_id :
    var.provider_type == "gcp" ? module.gcp_gke[0].node_security_group_id :
    null
  )
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA (AWS only)"
  value = (
    var.provider_type == "aws" ? module.aws_eks[0].oidc_provider_arn : null
  )
}
