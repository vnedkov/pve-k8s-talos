resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes
  node_name = each.value.host_node

  name        = each.key
  description = each.value.machine_type == "controlplane" ? "Talos Control Plane" : "Talos Worker"
  tags        = each.value.machine_type == "controlplane" ? ["k8s", "control-plane"] : ["k8s", "worker"]
  on_boot     = true
  vm_id       = each.value.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
  }

  # OS disk
  disk {
    datastore_id = each.value.datastore_id
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = each.value.disk_size
    file_id      = proxmox_virtual_environment_download_file.this[each.value.host_node].id
  }

  # Additional data disks - separating from the OS disk above
  dynamic "disk" {
    # each additional_disk is an object with a "key" that is its index within the list and a "value" being the object in the list
    for_each = { for idx, additional_disk in each.value.additional_disks: idx => additional_disk}
    iterator = additional_disk
      # If path_in_datastore is present, it will try to attach the existing disk instead of creating a new one
      content {
        datastore_id      = additional_disk.value.datastore_id
        interface         = "scsi${additional_disk.key + 1}"
        iothread          = additional_disk.value.iothread
        cache             = additional_disk.value.cache
        discard           = additional_disk.value.discard
        ssd               = additional_disk.value.ssd
        // Need to match the format of the existing file. If left unset it will default to qcow2
        file_format       = additional_disk.value.format
        size              = additional_disk.value.path_in_datastore == null ? additional_disk.value.size : null
        path_in_datastore = additional_disk.value.path_in_datastore
      }
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    datastore_id = each.value.datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${each.value.cidr_prefix}"
        gateway = var.cluster.gateway
      }
    }
  }

  # Commented out until I can get iGPU passthrough working
  # dynamic "hostpci" {
  #   for_each = each.value.igpu ? [1] : []
  #   content {
  #     # Passthrough iGPU
  #     device  = "hostpci0"
  #     mapping = "iGPU"
  #     pcie    = true
  #     rombar  = true
  #     xvga    = false
  #   }
  # }
}
