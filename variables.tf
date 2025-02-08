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
    cidr_prefix  = optional(number, 24)
    mac_address  = string
    vm_id        = number
    cpu          = number # cpu cores
    ram          = number # ram size in MB
    disk_size    = optional(number, 20) # disk size in GB
    additional_disks = optional(list(object({
      size         = optional(number) # Size in GB
      datastore_id = optional(string, "local-lvm")
      format       = optional(string, "raw")
      iothread     = optional(bool, true)
      cache        = optional(string, "writethrough")
      discard      = optional(string, "on")
      ssd          = optional(bool, true)
      path_in_datastore = optional(string, null)
    })), [])
  }))
}

variable "machine_config_patches" {
  description = "Map of machine config patches, where node name is a key and value is a list of patches to apply to the node."
  type = map(list(string))
  default = {
    "" = []
  }
}