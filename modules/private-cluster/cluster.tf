/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This file was automatically generated from a template in ./autogen/main

/******************************************
  Create Container Cluster
 *****************************************/
resource "google_container_cluster" "primary" {
  provider = google

  name            = var.name
  description     = var.description
  project         = var.project_id
  resource_labels = var.cluster_resource_labels

  location          = local.location
  node_locations    = local.node_locations
  cluster_ipv4_cidr = var.cluster_ipv4_cidr
  network           = "projects/${local.network_project_id}/global/networks/${var.network}"
  dynamic "network_policy" {
    for_each = local.cluster_network_policy

    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }

  dynamic "release_channel" {
    for_each = local.release_channel

    content {
      channel = release_channel.value.channel
    }
  }

  subnetwork = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"

  default_snat_status {
    disabled = var.disable_default_snat
  }

  min_master_version = var.release_channel == null || var.release_channel == "UNSPECIFIED" ? local.master_version : null

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  cluster_autoscaling {
    enabled = var.cluster_autoscaling.enabled
    dynamic "auto_provisioning_defaults" {
      for_each = var.cluster_autoscaling.enabled ? [1] : []

      content {
        service_account = local.service_account
        oauth_scopes    = local.node_pools_oauth_scopes["all"]
      }
    }
    dynamic "resource_limits" {
      for_each = local.autoscaling_resource_limits
      content {
        resource_type = lookup(resource_limits.value, "resource_type")
        minimum       = lookup(resource_limits.value, "minimum")
        maximum       = lookup(resource_limits.value, "maximum")
      }
    }
  }
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }
  default_max_pods_per_node = var.default_max_pods_per_node
  enable_shielded_nodes     = var.enable_shielded_nodes

  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [var.enable_binary_authorization] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = local.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }

  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }


    network_policy_config {
      disabled = !var.network_policy
    }

    dns_cache_config {
      enabled = var.dns_cache
    }

    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver
    }
  }

  datapath_provider = var.datapath_provider

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  maintenance_policy {
    dynamic "recurring_window" {
      for_each = local.cluster_maintenance_window_is_recurring
      content {
        start_time = var.maintenance_start_time
        end_time   = var.maintenance_end_time
        recurrence = var.maintenance_recurrence
      }
    }

    dynamic "daily_maintenance_window" {
      for_each = local.cluster_maintenance_window_is_daily
      content {
        start_time = var.maintenance_start_time
      }
    }

    dynamic "maintenance_exclusion" {
      for_each = var.maintenance_exclusions
      content {
        exclusion_name = maintenance_exclusion.value.name
        start_time     = maintenance_exclusion.value.start_time
        end_time       = maintenance_exclusion.value.end_time

        dynamic "exclusion_options" {
          for_each = maintenance_exclusion.value.exclusion_scope == null ? [] : [maintenance_exclusion.value.exclusion_scope]
          content {
            scope = exclusion_options.value
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [node_pool, initial_node_count, resource_labels["asmv"], resource_labels["mesh_id"]]
  }

  dynamic "dns_config" {
    for_each = var.cluster_dns_provider == "CLOUD_DNS" ? [1] : []
    content {
      cluster_dns        = var.cluster_dns_provider
      cluster_dns_scope  = var.cluster_dns_scope
      cluster_dns_domain = var.cluster_dns_domain
    }
  }

  timeouts {
    create = lookup(var.timeouts, "create", "45m")
    update = lookup(var.timeouts, "update", "45m")
    delete = lookup(var.timeouts, "delete", "45m")
  }
  node_pool {
    name               = "default-pool"
    initial_node_count = var.initial_node_count

    node_config {
      image_type       = lookup(var.node_pools[0], "image_type", "COS_CONTAINERD")
      machine_type     = lookup(var.node_pools[0], "machine_type", "e2-medium")
      min_cpu_platform = lookup(var.node_pools[0], "min_cpu_platform", "")
      dynamic "gcfs_config" {
        for_each = lookup(var.node_pools[0], "enable_gcfs", false) ? [true] : []
        content {
          enabled = gcfs_config.value
        }
      }

      dynamic "gvnic" {
        for_each = lookup(var.node_pools[0], "enable_gvnic", false) ? [true] : []
        content {
          enabled = gvnic.value
        }
      }

      service_account = lookup(var.node_pools[0], "service_account", local.service_account)

      tags = concat(
        lookup(local.node_pools_tags, "default_values", [true, true])[0] ? [local.cluster_network_tag] : [],
        lookup(local.node_pools_tags, "default_values", [true, true])[1] ? ["${local.cluster_network_tag}-default-pool"] : [],
        lookup(local.node_pools_tags, "all", []),
        lookup(local.node_pools_tags, var.node_pools[0].name, []),
      )

      dynamic "workload_metadata_config" {
        for_each = local.cluster_node_metadata_config

        content {
          mode = workload_metadata_config.value.mode
        }
      }

      metadata = local.node_pools_metadata["all"]


      shielded_instance_config {
        enable_secure_boot          = lookup(var.node_pools[0], "enable_secure_boot", false)
        enable_integrity_monitoring = lookup(var.node_pools[0], "enable_integrity_monitoring", true)
      }
    }
  }

  dynamic "resource_usage_export_config" {
    for_each = var.resource_usage_export_dataset_id != "" ? [{
      enable_network_egress_metering       = var.enable_network_egress_export
      enable_resource_consumption_metering = var.enable_resource_consumption_export
      dataset_id                           = var.resource_usage_export_dataset_id
    }] : []

    content {
      enable_network_egress_metering       = resource_usage_export_config.value.enable_network_egress_metering
      enable_resource_consumption_metering = resource_usage_export_config.value.enable_resource_consumption_metering
      bigquery_destination {
        dataset_id = resource_usage_export_config.value.dataset_id
      }
    }
  }

  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [{
      enable_private_nodes    = var.enable_private_nodes,
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }] : []

    content {
      enable_private_endpoint = private_cluster_config.value.enable_private_endpoint
      enable_private_nodes    = private_cluster_config.value.enable_private_nodes
      master_ipv4_cidr_block  = private_cluster_config.value.master_ipv4_cidr_block
    }
  }

  remove_default_node_pool = var.remove_default_node_pool

  dynamic "database_encryption" {
    for_each = var.database_encryption

    content {
      key_name = database_encryption.value.key_name
      state    = database_encryption.value.state
    }
  }

  dynamic "workload_identity_config" {
    for_each = local.cluster_workload_identity_config

    content {
      workload_pool = workload_identity_config.value.workload_pool
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = local.cluster_authenticator_security_group
    content {
      security_group = authenticator_groups_config.value.security_group
    }
  }

  notification_config {
    pubsub {
      enabled = var.notification_config_topic != "" ? true : false
      topic   = var.notification_config_topic
    }
  }
}
/******************************************
  Create Container Cluster node pools
 *****************************************/
resource "google_container_node_pool" "pools" {
  provider = google
  for_each = local.node_pools

  name     = each.key
  project  = var.project_id
  location = local.location
  // use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  cluster = google_container_cluster.primary.name

  version = lookup(each.value, "auto_upgrade", local.default_auto_upgrade) ? "" : lookup(
    each.value,
    "version",
    google_container_cluster.primary.min_master_version,
  )

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "initial_node_count",
    lookup(each.value, "min_count", 1)
  ) : null

  max_pods_per_node = lookup(each.value, "max_pods_per_node", null)

  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count = lookup(autoscaling.value, "min_count", 1)
      max_node_count = lookup(autoscaling.value, "max_count", 100)
    }
  }


  management {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", local.default_auto_upgrade)
  }

  upgrade_settings {
    max_surge       = lookup(each.value, "max_surge", 1)
    max_unavailable = lookup(each.value, "max_unavailable", 0)
  }

  node_config {
    image_type       = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type     = lookup(each.value, "machine_type", "e2-medium")
    min_cpu_platform = lookup(each.value, "min_cpu_platform", "")
    dynamic "gcfs_config" {
      for_each = lookup(each.value, "enable_gcfs", false) ? [true] : []
      content {
        enabled = gcfs_config.value
      }
    }
    dynamic "gvnic" {
      for_each = lookup(each.value, "enable_gvnic", false) ? [true] : []
      content {
        enabled = gvnic.value
      }
    }
    labels = merge(
      lookup(lookup(local.node_pools_labels, "default_values", {}), "cluster_name", true) ? { "cluster_name" = var.name } : {},
      lookup(lookup(local.node_pools_labels, "default_values", {}), "node_pool", true) ? { "node_pool" = each.value["name"] } : {},
      local.node_pools_labels["all"],
      local.node_pools_labels[each.value["name"]],
    )
    metadata = merge(
      lookup(lookup(local.node_pools_metadata, "default_values", {}), "cluster_name", true) ? { "cluster_name" = var.name } : {},
      lookup(lookup(local.node_pools_metadata, "default_values", {}), "node_pool", true) ? { "node_pool" = each.value["name"] } : {},
      local.node_pools_metadata["all"],
      local.node_pools_metadata[each.value["name"]],
      {
        "disable-legacy-endpoints" = var.disable_legacy_metadata_endpoints
      },
    )
    dynamic "taint" {
      for_each = concat(
        local.node_pools_taints["all"],
        local.node_pools_taints[each.value["name"]],
      )
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
    tags = concat(
      lookup(local.node_pools_tags, "default_values", [true, true])[0] ? [local.cluster_network_tag] : [],
      lookup(local.node_pools_tags, "default_values", [true, true])[1] ? ["${local.cluster_network_tag}-${each.value["name"]}"] : [],
      local.node_pools_tags["all"],
      local.node_pools_tags[each.value["name"]],
    )

    local_ssd_count = lookup(each.value, "local_ssd_count", 0)
    disk_size_gb    = lookup(each.value, "disk_size_gb", 100)
    disk_type       = lookup(each.value, "disk_type", "pd-standard")


    service_account = lookup(
      each.value,
      "service_account",
      local.service_account,
    )
    preemptible = lookup(each.value, "preemptible", false)
    spot        = lookup(each.value, "spot", false)

    oauth_scopes = concat(
      local.node_pools_oauth_scopes["all"],
      local.node_pools_oauth_scopes[each.value["name"]],
    )

    guest_accelerator = [
      for guest_accelerator in lookup(each.value, "accelerator_count", 0) > 0 ? [{
        type               = lookup(each.value, "accelerator_type", "")
        count              = lookup(each.value, "accelerator_count", 0)
        gpu_partition_size = lookup(each.value, "gpu_partition_size", null)
        }] : [] : {
        type               = guest_accelerator["type"]
        count              = guest_accelerator["count"]
        gpu_partition_size = guest_accelerator["gpu_partition_size"]
      }
    ]

    dynamic "workload_metadata_config" {
      for_each = local.cluster_node_metadata_config

      content {
        mode = lookup(each.value, "node_metadata", workload_metadata_config.value.mode)
      }
    }


    shielded_instance_config {
      enable_secure_boot          = lookup(each.value, "enable_secure_boot", false)
      enable_integrity_monitoring = lookup(each.value, "enable_integrity_monitoring", true)
    }
  }

  lifecycle {
    ignore_changes = [initial_node_count]
    create_before_destroy = true
  }

  timeouts {
    create = lookup(var.timeouts, "create", "45m")
    update = lookup(var.timeouts, "update", "45m")
    delete = lookup(var.timeouts, "delete", "45m")
  }

}
resource "google_container_node_pool" "windows_pools" {
  provider = google
  for_each = local.windows_node_pools

  name     = each.key
  project  = var.project_id
  location = local.location
  // use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  cluster = google_container_cluster.primary.name

  version = lookup(each.value, "auto_upgrade", local.default_auto_upgrade) ? "" : lookup(
    each.value,
    "version",
    google_container_cluster.primary.min_master_version,
  )

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "initial_node_count",
    lookup(each.value, "min_count", 1)
  ) : null

  max_pods_per_node = lookup(each.value, "max_pods_per_node", null)

  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count = lookup(autoscaling.value, "min_count", 1)
      max_node_count = lookup(autoscaling.value, "max_count", 100)
    }
  }


  management {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", local.default_auto_upgrade)
  }

  upgrade_settings {
    max_surge       = lookup(each.value, "max_surge", 1)
    max_unavailable = lookup(each.value, "max_unavailable", 0)
  }

  node_config {
    image_type       = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type     = lookup(each.value, "machine_type", "e2-medium")
    min_cpu_platform = lookup(each.value, "min_cpu_platform", "")
    dynamic "gcfs_config" {
      for_each = lookup(each.value, "enable_gcfs", false) ? [true] : []
      content {
        enabled = gcfs_config.value
      }
    }
    dynamic "gvnic" {
      for_each = lookup(each.value, "enable_gvnic", false) ? [true] : []
      content {
        enabled = gvnic.value
      }
    }
    labels = merge(
      lookup(lookup(local.node_pools_labels, "default_values", {}), "cluster_name", true) ? { "cluster_name" = var.name } : {},
      lookup(lookup(local.node_pools_labels, "default_values", {}), "node_pool", true) ? { "node_pool" = each.value["name"] } : {},
      local.node_pools_labels["all"],
      local.node_pools_labels[each.value["name"]],
    )
    metadata = merge(
      lookup(lookup(local.node_pools_metadata, "default_values", {}), "cluster_name", true) ? { "cluster_name" = var.name } : {},
      lookup(lookup(local.node_pools_metadata, "default_values", {}), "node_pool", true) ? { "node_pool" = each.value["name"] } : {},
      local.node_pools_metadata["all"],
      local.node_pools_metadata[each.value["name"]],
      {
        "disable-legacy-endpoints" = var.disable_legacy_metadata_endpoints
      },
    )
    dynamic "taint" {
      for_each = concat(
        local.node_pools_taints["all"],
        local.node_pools_taints[each.value["name"]],
      )
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
    tags = concat(
      lookup(local.node_pools_tags, "default_values", [true, true])[0] ? [local.cluster_network_tag] : [],
      lookup(local.node_pools_tags, "default_values", [true, true])[1] ? ["${local.cluster_network_tag}-${each.value["name"]}"] : [],
      local.node_pools_tags["all"],
      local.node_pools_tags[each.value["name"]],
    )

    local_ssd_count = lookup(each.value, "local_ssd_count", 0)
    disk_size_gb    = lookup(each.value, "disk_size_gb", 100)
    disk_type       = lookup(each.value, "disk_type", "pd-standard")


    service_account = lookup(
      each.value,
      "service_account",
      local.service_account,
    )
    preemptible = lookup(each.value, "preemptible", false)
    spot        = lookup(each.value, "spot", false)

    oauth_scopes = concat(
      local.node_pools_oauth_scopes["all"],
      local.node_pools_oauth_scopes[each.value["name"]],
    )

    guest_accelerator = [
      for guest_accelerator in lookup(each.value, "accelerator_count", 0) > 0 ? [{
        type               = lookup(each.value, "accelerator_type", "")
        count              = lookup(each.value, "accelerator_count", 0)
        gpu_partition_size = lookup(each.value, "gpu_partition_size", null)
        }] : [] : {
        type               = guest_accelerator["type"]
        count              = guest_accelerator["count"]
        gpu_partition_size = guest_accelerator["gpu_partition_size"]
      }
    ]

    dynamic "workload_metadata_config" {
      for_each = local.cluster_node_metadata_config

      content {
        mode = lookup(each.value, "node_metadata", workload_metadata_config.value.mode)
      }
    }


    shielded_instance_config {
      enable_secure_boot          = lookup(each.value, "enable_secure_boot", false)
      enable_integrity_monitoring = lookup(each.value, "enable_integrity_monitoring", true)
    }
  }

  lifecycle {
    ignore_changes = [initial_node_count]

  }

  timeouts {
    create = lookup(var.timeouts, "create", "45m")
    update = lookup(var.timeouts, "update", "45m")
    delete = lookup(var.timeouts, "delete", "45m")
  }

  depends_on = [google_container_node_pool.pools[0]]
}
