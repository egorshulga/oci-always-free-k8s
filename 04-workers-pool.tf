resource "oci_core_instance_configuration" "worker_pool_configuration" {
  compartment_id = oci_identity_compartment.tf_compartment.id
  display_name   = "worker-pool-configuration"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id = oci_identity_compartment.tf_compartment.id

      display_name = "worker"

      shape = "VM.Standard.E2.1.Micro"
      shape_config {
        ocpus         = 1
        memory_in_gbs = 1
      }
      source_details {
        source_type = "image"
        image_id    = data.oci_core_images.ubuntu.images[0].id
      }

      create_vnic_details {
        assign_public_ip          = false
        subnet_id                 = oci_core_subnet.vcn_public_subnet.id
        assign_private_dns_record = true
        hostname_label            = "worker"
      }

      metadata = {
        ssh_authorized_keys = file(var.leader_ssh_key_pub)
      }
    }
  }
}

resource "oci_core_instance_pool" "worker_pool" {
  compartment_id            = oci_identity_compartment.tf_compartment.id
  instance_configuration_id = oci_core_instance_configuration.worker_pool_configuration.id
  size                      = 1
  display_name              = "worker-pool"

  placement_configurations {
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    primary_subnet_id   = oci_core_subnet.vcn_public_subnet.id
  }
}

# data "oci_core_instance_pool_instances" "worker_pool_instances" {
#   compartment_id = oci_identity_compartment.tf_compartment.id
#   instance_pool_id = oci_core_instance_pool.worker_pool.id
# }

# data "oci_core_instance" "worker_pool_instance" {
#   for_each = {
#     for instance in data.oci_core_instance_pool_instances.worker_pool_instances.instances:
#     instance.id => instance
#   }
#   instance_id = each.key
# }

# output "worker_pool_instances" {
#   value = data.oci_core_instance.worker_pool_instance
# }
