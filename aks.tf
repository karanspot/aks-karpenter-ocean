#resource "azurerm_resource_group" "rg" {
#  name     = "karpenter"
#  location = var.location
#}

#resource "azurerm_virtual_network" "vnet" {
#  name                = var.cluster_name
#  location            = var.location
#  resource_group_name = var.resource_group_name
#  address_space       = ["10.110.0.0/12"]
#}

#resource "azurerm_subnet" "subnet" {
#  name                 = var.cluster_name
#  resource_group_name  = var.resource_group_name
#  virtual_network_name = azurerm_virtual_network.vnet.name
#  address_prefixes     = ["10.110.0.0/12"]
#}



module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.3.0"
  cluster_name        = var.cluster_name
  prefix              = "karpenter"
  resource_group_name = var.resource_group_name
  sku_tier            = "Standard"
  kubernetes_version  = var.kubernetes_version

  #vnet_subnet_id      = azurerm_subnet.subnet.id

  network_plugin                    = "azure"
  network_policy                    = "cilium"
  ebpf_data_plane = "cilium"
  network_plugin_mode = "overlay"
  enable_auto_scaling    = false
  #enable_node_public_ip = false
  rbac_aad = false

  agents_labels = {
    "env" : "karpenter"
  }
  agents_tags = {
    "env" : "karpenter",
    "Creator" : "karan@netapp.com"
  }

  #node_pools = var.node_pools

}

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name

  depends_on = [module.aks]
}


resource "helm_release" "azure-node-termination-handler" {
  name       = "aks-node-termination-handler"
  repository = "https://maksim-paskal.github.io/aks-node-termination-handler/"
  chart      = "aks-node-termination-handler"
  namespace  = "kube-system"

  set {
    name  = "priorityClassName"
    value = "system-node-critical"
  }
  depends_on = [module.aks]
}



resource "terraform_data" "azcliexec" {
#Enable NAP on the aks cluster and get locally kubectl config
    provisioner "local-exec" {
      command = <<EOT
      az aks update --name ${var.cluster_name} --resource-group ${var.resource_group_name} --node-provisioning-mode Auto --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium
      az aks get-credentials --name ${var.cluster_name} --resource-group ${var.resource_group_name} --overwrite-existing
      EOT
  }
  depends_on = [module.aks]
}



module "kubernetes-controller" {
  source = "spotinst/kubernetes-controller/ocean"

  # Credentials.
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account

  # Configuration.
  cluster_identifier = var.cluster_identifier

  depends_on = [module.aks, terraform_data.azcliexec]
}

module "ocean-aks-np" {
  source     = "git::https://github.com/spotinst/terraform-spotinst-ocean-aks-np-k8s.git?ref=bb76c8224538fdf325bfe430652c885cf661a66d"

  # Credentials.
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account



  ocean_cluster_name  = var.cluster_name

  vmsizes_filters_series                   = ["Dv3", "Dds_v4", "Dsv2"]

  // --- AKS ------------------------------------------------------------------------

  aks_region                             = var.oceanlocation
  aks_cluster_name                       = var.cluster_name
  aks_infrastructure_resource_group_name = var.aks_infrastructure_resource_group_name
  aks_resource_group_name                = var.resource_group_name

  // --------------------------------------------------------------------------------

  controller_cluster_id = var.cluster_identifier

  // --- virtualNodeGroupTemplate --------------------------------------

  availability_zones = [
    "1",
    "2",
    "3"
  ]

  enable_node_public_ip = false

  tags = {
    tagKey   = "Environment"
    tagValue = "Ocean"

    tagKey   = "Creator"
    tagValue = "karan@netapp.com"

  }

  labels =  { "env": "ocean"}
  taints = [{"key":"env","value":"ocean", "effect" : "NoSchedule"}]

  depends_on = [module.aks, module.kubernetes-controller]

}

module "ocean-aks-np-vng" {

  source = "spotinst/ocean-aks-np-k8s-vng/spotinst"
  ocean_vng_name = "workers"
  ocean_id = module.ocean-aks-np.ocean_id

  labels = { "env": "ocean"}
  taints = [{"key":"env","value":"ocean", "effect" : "NoSchedule"}]
  vmsizes_filters_series = ["Dv3", "Dds_v4", "Dsv2"]
  enable_node_public_ip = false
  depends_on = [module.kubernetes-controller, module.ocean-aks-np]

}

module "ocean-metric-exporter" {
  source                          = "spotinst/ocean-metric-exporter/spotinst"
  namespace                       = "spot-system"
  metricsconfiguration_categories = ["scaling", "cost_analysis"]
  config_map_name                 = "ocean-controller-ocean-kubernetes-controller"
  secret_name                     = "ocean-controller-ocean-kubernetes-controller"
  depends_on                      = [ module.aks, module.kubernetes-controller, module.ocean-aks-np , module.ocean-aks-np-vng]

}


output "aks_name" {
  description = "The `azurerm_kubernetes_cluster`'s name."
  value       = module.aks.aks_name
}

output "ocean_id" {
  value = module.ocean-aks-np.ocean_id
}

output "ocean_vng_id" {
  value = module.ocean-aks-np-vng.vng_id
}
