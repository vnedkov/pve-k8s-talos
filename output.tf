output "machine_config" {
  value = data.talos_machine_configuration.this
}

output "client_configuration" {
  description = "talos client (talosctl) configuration"
  value     = data.talos_client_configuration.this
  sensitive = true
}

output "kube_config" {
  description = "cluster kubeconfig"
  value =  talos_cluster_kubeconfig.this
  sensitive = true
}