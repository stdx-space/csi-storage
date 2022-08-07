variable "driver_config_file" {
  type = string
}

// https://github.com/democratic-csi/democratic-csi/issues/168#issuecomment-1082102808
job "hostpath-csi-driver" {
  datacenters = ["dc1"]
  type        = "service"

  group "driver" {

    volume "data" {
      type   = "host"
      source = "data"
    }

    task "driver" {
      driver = "docker"

      volume_mount {
        volume      = "data"
        destination = "/var/lib/csi-local-hostpath"
      }

      env {
        // https://github.com/democratic-csi/democratic-csi/blob/4ff8db5b98c9dccb36842cb87d105c6b4dbda6d0/src/driver/index.js#L543
        // fix node id with env variable CSI_NODE_ID to prevent node_id change when restarting the driver (docker container hostname changed)
        // without it the node_id will be changed and jobs cannot be placed on the node anymore
        CSI_NODE_ID = node.unique.name
      }

      config {
        image = "democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.5.0",
          "--csi-name=org.democratic-csi.local",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=debug",
          "--csi-mode=controller",
          "--csi-mode=node",
          "--server-socket=/csi/csi.sock",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "hostpath-csi"
        type      = "monolith"
        mount_dir = "/csi"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"
        data        = var.driver_config_file
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
