# pve-k8-talos
## Terraform module to install a Talos Kubernetes cluster
Installs a Kubernetes cluster with nodes running [Talos Linux](https://www.talos.dev/)

## Input Parameters
| Parameter | Type | Optional | Description |
| :- | :-: | :-: | :- |
| image        |   object | No |A variable, describing what image to download|
| image.version|   string | No |Talos OS version|
| image.arch|   string | Yes |CPU architecture - amd64 or arm64. Default is amd64 |
| image.platform|   string | Yes |Platform - metal, aws, gcp, equinixMetal, azure, digital-ocean, openstack, vmware, akamai, cloudstack, hcloud, nocloud, oracle, upcloud or vultr. Default is nocloud |
| image.proxmox_datastore|   string | No |Proxmox datastore. Defailt is local|
| image.extensions|   string | No |list of names to filter out extensions. Default is [] - empty list, which will include all extensions|
|||||
| cluster | object | No | A variable, describing Talos Cluster parameters |
| cluster.name | string | No | Name of the cluster |
| cluster.endpoint | string | No | IP address of a control plane node. The API endpoint URL will be derived from it - "https://${var.cluster.endpoint}:6443. Some resources require IP, others - a full URL|
| cluster.gateway | string | No | LAN Gateway IP address |
| cluster.talos_version | string | No | Talos OS version |
| cluster.proxmox_cluster | string | No | Name of the Proxmox cluster |
|||||
| nodes | map(object) | No | A variable, describing cluster nodes. Node name is used as a map key and also treated as a hostname. Each objects describes parameter of a virtual machine that will be created. |
| node.host_node | string | No | Name of the proxmox node where the virtual machine will be created |
| node.machine_type | string | No | `controlplane` or `worker` |
| node.datastore_id | string | Yes | Name of the data store within proxmox node, where the startup disk will be created |
| node.ip | string | No | Static IPv4 address to be assigned to the virtual machine |
| node.cidr_prefix | number | Yes | CIDR prefix. Default is 24 (256 addresses) |
| node.mac_address | string | No | MAC address to be assigned to the virtual machine |
| node.vm_id | number | No | Virtual machine ID within proxmox |
| node.cpu | number | No | Number of virtual CPU cores |
| node.ram | number | No | Size of RAM in MB to be allocated |
| node.disk_size | number | Yes | Disk Size in GB with default value of 20GB |


## Sample configuration
```tf
cluster = {
  name            = "talos"
  endpoint        = "192.168.0.150"
  gateway         = "192.168.0.1"
  talos_version   = "v1.8.1"
  proxmox_cluster = "pve"
}

image = {
  version = "v1.8.1"
  proxmox_datastore = "local"
  extensions = [
      "i915-ucode",
      "intel-ucode",
      "qemu-guest-agent"
    ]
}

nodes = {
  "ctrl-00" = {
    host_node     = "pve"
    machine_type  = "controlplane"
    ip            = "192.168.0.150"
    mac_address   = "BC:24:11:2E:C8:00"
    vm_id         = 800
    cpu           = 4
    ram           = 4096 #4GB
    datastore_id  = "local-lvm"
  }
  "work-00" = {
    host_node     = "pve2"
    machine_type  = "worker"
    ip            = "192.168.0.160"
    mac_address   = "BC:24:11:2E:C9:00"
    vm_id         = 810
    cpu           = 4
    ram           = 4096 #4GB
    datastore_id  = "local-lvm"
  }
}

proxmox = {
  name         = "pve"
  cluster_name = "pve"
  endpoint     = "https://192.168.0.30:8006"
  insecure     = true
  username     = "root"
  # Generate a real token from Proxmox console and add it below. The format is token_id=token_value, so root@pam!terraform in my case is my token id
  api_token    = "root@pam!terraform=00000000-1111-2222-3333-444444444444"
}
```