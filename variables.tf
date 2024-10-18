variable "image" {
  description = "Talos image configuration"
  type = object({
    version           = string
    arch              = optional(string, "amd64")
    platform          = optional(string, "nocloud")
    proxmox_datastore = optional(string, "local")
    extensions        = optional(list(string))
  })
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name            = string
    endpoint        = string
    gateway         = string
    talos_version   = string
    proxmox_cluster = string
  })
}

# A variable to store the configuration for cluster nodes
variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node    = string
    machine_type = string
    datastore_id = optional(string, "local-zfs")
    ip           = string
    mac_address  = string
    vm_id        = number
    cpu          = number
    ram          = number
  }))
}

# A variable to store the patches for controlplane nodes
# if useDefault is true, the default patches will be used. Otherwise, the provided patches will be used
variable "controlplane_patches" {
  description = "Patches for controlplane nodes"
  type        = object({
    useDefault = bool
    patches = list(string)
  })
  default = {
    useDefault = true
    patches    = []
  }
}

# A variable to store the patches for worker nodes
# if useDefault is true, the default patches will be used. Otherwise, the provided patches will be used
variable "worker_patches" {
  description = "Patches for worker nodes"
  type        = object({
    useDefault = bool
    patches = list(string)
  })
  default = {
    useDefault = true
    patches    = []
  }
}