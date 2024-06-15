
resource "kubernetes_service" "main" {
  metadata {
    name      = "dxu-${lower(var.owner)}-${lower(var.name)}"
    namespace = var.namespace
  }

  spec {
    selector = {
      "app" = "dxu-${lower(var.owner)}-${lower(var.name)}"

    }
    port {
      port        = 80
      target_port = 8888
    }

    type = "ClusterIP"
  }
}


# resource "kubernetes_ingress" "main" {
#   metadata {
#     name      = "dxu-${lower(var.owner)}-${lower(var.name)}"
#     namespace = var.namespace
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }


#   spec {
#     backend {
#       service_name = kubernetes_service.main.metadata[0].name
#       service_port = 80
#     }
#   }

# }

resource "kubernetes_ingress_v1" "main" {
  metadata {
    name      = "idp-${lower(var.name)}"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }

  }
  spec {
    rule {
      host = "idp-${lower(var.name)}-${lower(var.workspace_id)}.k3s.kr"
      http {

        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.main.metadata[0].name
              port {
                number = kubernetes_service.main.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
