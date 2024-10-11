# pve-k8-talos
## Terraform module to install a Talos Kubernetes cluster
Installs a Kubernetes cluster with nodes running [Talos Linux](https://www.talos.dev/)

## Parameters
| Parameter | Type | Optional | Description |
| :- | :-: | :-: | :- |
| image        |   object | No |Variable, describing what image to download|
| image.version|   string | No |Talos OS version|
| image.arch|   string | Yes |CPU architecture - amd64 or arm64. Default is amd64 |
| image.platform|   string | Yes |Platform - metal, aws, gcp, equinixMetal, azure, digital-ocean, openstack, vmware, akamai, cloudstack, hcloud, nocloud, oracle, upcloud or vultr. Default is nocloud |
| image.proxmox_datastore|   string | No |Proxmox datastore. Defailt is local|
| image.extensions|   string | No |list of names to filter out extensions. Default is [] - empty list, which will include all extensions|