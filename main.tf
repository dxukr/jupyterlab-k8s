
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.30.0"
    }
  }
}
provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  #   config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
  config_path = "~/.kube/config"
}


resource "kubernetes_deployment" "main" {
  count = 1
  depends_on = [
    kubernetes_persistent_volume_claim.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "dxu-${lower(var.owner)}-${lower(var.name)}"
    namespace = var.namespace
    labels = {
      "app"                        = "dxu-${lower(var.owner)}-${lower(var.name)}"
      "app.kubernetes.io/name"     = "${local.name}"
      "app.kubernetes.io/instance" = "${local.name}-${lower(var.owner)}-${lower(var.name)}"
      "app.kubernetes.io/part-of"  = local.name
      "kr.idp.resource"            = "true"
      "kr.idp.workspace.id"        = var.workspace_id
      "kr.idp.workspace.name"      = var.workspace_name
      "kr.idp.user.id"             = var.owner_id
      "kr.idp.user.username"       = var.owner
    }

  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "dxu-${lower(var.owner)}-${lower(var.name)}"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app"                    = "dxu-${lower(var.owner)}-${lower(var.name)}"
          "app.kubernetes.io/name" = local.name
        }
      }
      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 100
        }

        container {
          name              = "jupyter"
          image             = local.image
          image_pull_policy = "Always"
          command           = ["sh", "-c", var.init_script]
          security_context {
            run_as_user = "1000"
          }
          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits = {
              "cpu"    = "${var.cpu}"
              "memory" = "${var.memory}Gi"
            }
          }
          volume_mount {
            mount_path = local.mount_path
            name       = "home"
            read_only  = false
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
            read_only  = false
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["idp-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}


/////////////////

