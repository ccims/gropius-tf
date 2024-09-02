resource "kubernetes_service" "api_public" {
  metadata {
    name = "api-public"
    labels = {
      "gropius.app" = "api-public"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    port {
      name        = "8080"
      port        = 8080
      target_port = 8080
    }

    selector = {
      "gropius.app" = "api-public"
    }
  }
}

resource "kubernetes_deployment" "api_public" {
  metadata {
    name = "api-public"
    labels = {
      "gropius.app" = "api-public"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "gropius.app" = "api-public"
      }
    }

    template {
      metadata {
        labels = {
          "gropius.app" = "api-public"
        }
      }

      spec {
        container {
          name              = "api-public"
          image             = "ghcr.io/ccims/gropius-api-public:${var.gropius_version}"
          image_pull_policy = "Always"


          env {
            name  = "SERVER_ADDRESS"
            value = "0.0.0.0"
          }

          env {
            name  = "GROPIUS_CORE_CREATE_INDICES_ON_STARTUP"
            value = "true"
          }

          env {
            name  = "GRAPHGLUE_CORE_USE_NEO4J_PLUGIN"
            value = "true"
          }

          env {
            name = "GROPIUS_API_PUBLIC_JWT_PUBLIC_KEY"
            value_from {
              secret_key_ref {
                name = "login-service-keys"
                key  = "oauth_public_key"
              }
            }
          }

          env {
            name  = "LOGGING_LEVEL_ROOT"
            value = "ERROR"
          }

          env {
            name = "SPRING_NEO4J_AUTHENTICATION_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.neo4j_password_secret.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "SPRING_NEO4J_AUTHENTICATION_USERNAME"
            value = "neo4j"
          }

          env {
            name  = "SPRING_NEO4J_URI"
            value = "bolt://neo4j-db:7687"
          }

          liveness_probe {
            http_get {
              port = "8080"
              path = "/health"
            }
            failure_threshold     = 20
            initial_delay_seconds = 120
            period_seconds        = 5
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}
