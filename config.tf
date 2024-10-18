# Generate machine secrets
resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

# Create a configuration for each node
data "talos_machine_configuration" "this" {
  for_each         = var.nodes
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.endpoint}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches   = each.value.machine_type == "controlplane" ? var.controlplane_patches.useDefault ? [
    # If the node is a controlplane and no custom patches are provided, use the default machine config
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
        hostname       = each.key
        # Use cluster name as a region and node name as a zone
        zone_name      = each.value.host_node
        region_name    = var.cluster.proxmox_cluster
      })
  # otherwise use custom machine config
  ] : var.controlplane_patches.patches : var.worker_patches.useDefault ? [
     # If the node is a worker node and no custom patches are provided, use the default machine config
   templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
      hostname     = each.key
      node_name    = each.value.host_node
      cluster_name = var.cluster.proxmox_cluster
    })
  # otherwise use custom machine config
  ] : var.worker_patches.patches
}

# Apply talos configuration
resource "talos_machine_configuration_apply" "this" {
  depends_on = [proxmox_virtual_environment_vm.this]
  for_each                    = var.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }
}

# Bootstrap the cluster - https://www.sidero.dev/v0.6/guides/bootstrapping/
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this 
  ]
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
