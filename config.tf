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

  config_patches   = try(var.machine_config_patches[each.key], 
    # If no patches are found in the map, use the default machine config
    each.value.machine_type == "controlplane" ? [ 
      templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname       = each.key
        # Use cluster name as a region and node name as a zone
        zone_name      = each.value.host_node
        region_name    = var.cluster.proxmox_cluster
    })] : [
      templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
        hostname     = each.key
        zone_name    = each.value.host_node
        region_name  = var.cluster.proxmox_cluster
    })]
  )
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
