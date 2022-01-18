output "cluster_public_address" {
  value = local.cluster_public_address
}

output "control_plane_setup" {
  value = null_resource.control_plane_setup.id
}