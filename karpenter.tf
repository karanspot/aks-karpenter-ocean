resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: worker
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: kubernetes.io/arch
              operator: In
              values:
              - amd64
            - key: kubernetes.io/os
              operator: In
              values:
              - linux
            - key: karpenter.azure.com/sku-name
              operator: In
              values:
              - Standard_DS1_v2
              - Standard_D2s_v3
              - Standard_D2as_v4
              - Standard_D8s_v3
      limits:
        cpu: 5000
  YAML

  depends_on = [module.aks, terraform_data.azcliexec]
}
