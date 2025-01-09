variable "subscription_id" {
  description = "Azure Subsciption id to create AKS cluster in"
  default     = ""
  sensitive   = true
}


variable "tenant_id" {
  description = "Azure Tenant id to create AKS cluster in"
  default     = ""
  sensitive   = true
}

variable "spotinst_account" {
  description = "Ocean account id to create Ocean cluster in"
  default     = ""
  sensitive   = true
}

variable "spotinst_token" {
  description = "Ocean API token"
  default     = ""
  sensitive   = true
}

variable "resource_group_name" {
  description = "Azure Resource group name to create AKS cluster in"
  default     = "karpenter"
}

variable "aks_infrastructure_resource_group_name" {
  description = "Azure Infrastructure Resource group name to create AKS cluster in"
  default     = "MC_karpenter_karpenter-test_eastus"
}

variable "location" {
  description = "AKS cluster location"
  default     = "East US"
}

variable "oceanlocation" {
  description = "Ocean cluster location"
  default     = "eastus"
}

variable "cluster_name" {
  description = "AKS cluster name"
    default     = "aks-karpenter"
}

variable "kubernetes_version" {
  description = "K8s version of the AKS cluster"
  default     = "1.30.6"
}

variable "cluster_identifier" {
  description = "Ocean controller cluster identifier"
  default     = "ocean-aks-karpenter"

}

variable "node_pools" {
  type = map(object({
    name = string
    vm_size = string
    node_count = number
    enable_auto_scaling = bool
    enable_node_public_ip = bool
    priority = string
    tags = map(string)
    node_labels = map(string)
    node_taints = list(string)
    create_before_destroy = bool
  }))

  default = {
        nodes = {
          name                  = "worker"
          vm_size               = "Standard_D2s_v3"
          node_count            = 1
          enable_auto_scaling   = "false"
          enable_node_public_ip = "false"
          create_before_destroy = "false"
          priority = "Spot"
          tags = {
            "Nodes" : "worker",
            "Creator" : "karan@netapp.com"
          }
          node_labels = {
            "Nodes" : "worker"
          }
          node_taints = ["node=worker:NoSchedule"]

    }
  }
}
