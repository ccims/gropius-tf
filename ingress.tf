resource "kubernetes_ingress_v1" "gropius_ingress" {
  metadata {
    name      = "gropius-ingress"
    namespace = kubernetes_namespace.gropius.metadata[0].name
    annotations = {
        "cert-manager.io/cluster-issuer": "letsencrypt-production"
        "kubernetes.io/ingress.class": "nginx"
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

      host = "frontend.gropius.duckdns.org"
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
      hosts = ["frontend.gropius.duckdns.org"]
      secret_name = "frontend.gropius.duckdns.org-tls"
    }
  }
}
