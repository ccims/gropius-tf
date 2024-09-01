resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      "gropius.app" = "frontend"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    port {
      name        = "80"
      port        = 80
      target_port = 80
    }

    selector = {
      "gropius.app" = "frontend"
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
          name              = "frontend"
          image             = "ghcr.io/ccims/gropius-frontend:${var.gropius_version}"
          image_pull_policy = "Always"

          env {
            name  = "LOGIN_SERVICE_ENDPOINT"
            value = "http://login-service:3000"
          }

          env {
            name  = "API_PUBLIC_ENDPOINT"
            value = "http://api-public:8080/graphql"
          }

          liveness_probe {
            http_get {
              port = "80"
              path = "/"
            }
            failure_threshold     = 20
            initial_delay_seconds = 30
            period_seconds        = 5
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}
