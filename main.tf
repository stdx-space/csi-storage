terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = ">= 1.4.17"
    }
  }

  cloud {
    organization = "syoi-org"

    workspaces {
      name = "csi-storage"
    }
  }
}

resource "nomad_job" "storage_monolith" {
  jobspec = file("${path.module}/hostpath-csi-driver.nomad")
  hcl2 {
    enabled = true
    vars = {
      driver_config_file = file("${path.module}/driver-config-file.yml"),
    }
  }
}
