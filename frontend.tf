resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      "gropius.app" = "frontend"
    }
  }

  spec {
    port {
      name        = "80"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      "gropius.app" = "frontend"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "gropius.app" = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          "gropius.app" = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = "ghcr.io/ccims/gropius-frontend:main"

          env {
            name  = "LOGIN_OAUTH_CLIENT_ID"
            value = random_uuid.default_auth_client_id.result
          }

          liveness_probe {
            exec {
              command = ["wget", "http://localhost:80", "||", "exit", "1"]
            }
            failure_threshold     = 20
            initial_delay_seconds = 3
            period_seconds        = 1
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}