## Prerequisites
Below are prerequisites to provision AKS with NodeAutoProvisioning enabled(Karpenter):

| Name | Version |
|------|---------|
| <a name="requirement_AzureCLI"></a> [Azure CLI](#requirement\AzureCLI) | >= 2.67.0 |
| <a name="requirement_aks-preview"></a> [aks-preview](#requirement\aks-preview) | >= 0.5.170 |

Install the aks-preview Azure CLI extension:
```
az extension add --name aks-preview
az extension update --name aks-preview
```

Register the NodeAutoProvisioningPreview feature flag:
```
az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
```
Verify Registration:
```
az feature show --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
```
When the status reflects Registered, refresh the registration of the Microsoft.ContainerService resource provider:
```
az provider register --namespace Microsoft.ContainerService
```
Make sure Autoscale is disabled in your Node pools.

Enable NodeAutoProvisioning on an existing cluster (TF Module will run this cmd as local-exec after AKS cluster is created):
```
az aks update --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --node-provisioning-mode Auto --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium
```

In the JSON after running the Update command you should see NAP set to Auto mode:
```
"nodeProvisioningProfile": {
    "mode": "Auto"
  },
```




