locals {
  gropius_host = regex("(https?://)?([^/]+)", var.gropius_endpoint)[1]
}

resource "kubernetes_ingress_v1" "gropius_ingress" {
  count = var.gropius_endpoint != "" && startswith(var.gropius_endpoint, "https://") && var.enable_ingress ? 1 : 0

  metadata {
    name      = "gropius-ingress"
    namespace = kubernetes_namespace.gropius.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" : "letsencrypt-production"
      "kubernetes.io/ingress.class" : "nginx"
    }
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service.frontend.metadata[0].name
        port {
          number = 80
        }
      }
    }

    rule {

      host = local.gropius_host
      http {
        path {
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/"
        }
      }
    }

    tls {
      hosts       = [local.gropius_host]
      secret_name = "${local.gropius_host}-tls"
    }
  }
}
