data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.image.version
  filters = {
    names = var.image.extensions
  }
}

resource "talos_image_factory_schematic" "generated" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

output "schematic_id" {
  value = talos_image_factory_schematic.generated.id
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = toset(distinct([for k, v in var.nodes : v.host_node]))

  node_name               = each.key
  content_type            = "iso"
  datastore_id            = var.image.proxmox_datastore
  file_name               = "talos-${var.image.version}-${talos_image_factory_schematic.generated.id}-${var.image.platform}-${var.image.arch}.img"
  url                     = data.talos_image_factory_urls.this.urls.disk_image
  decompression_algorithm = "zst"
  overwrite               = false
}

data "talos_image_factory_urls" "this" {
  talos_version = var.image.version
  schematic_id  = talos_image_factory_schematic.generated.id
  platform      = var.image.platform
}