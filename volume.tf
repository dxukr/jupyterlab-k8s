


resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "${var.namespace}-${lower(var.owner)}-${lower(var.name)}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "${var.namespace}-pvc"
      "app.kubernetes.io/instance" = "${var.namespace}-pvc-${lower(var.owner)}-${lower(var.name)}"
      "app.kubernetes.io/part-of"  = "${var.namespace}"
      //Coder-specific labels.
      "kr.idp.resource"       = "true"
      "kr.idp.workspace.id"   = var.workspace_id
      "kr.idp.workspace.name" = var.workspace_name
      "kr.idp.user.id"        = var.owner_id
      "kr.idp.user.username"  = var.owner
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.disk}Gi"
      }
    }
  }
}
