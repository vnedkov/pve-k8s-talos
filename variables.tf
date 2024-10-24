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

variable "machine_config_patches" {
  description = "Map of machine config patches, where node name is a key and value is a list of patches to apply to the node."
  type = map(object({
    patches = list(string)
  }))
  default = {
    "" = {
      patches = []
    }
  }
}