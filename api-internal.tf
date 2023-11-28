resource "random_password" "internal_api_token" {
  length  = 20
  special = true
}

resource "kubernetes_service" "api_internal" {
  metadata {
    name = "api-internal"
    labels = {
      "gropius.app" = "api-internal"
    }
  }

  spec {
    port {
      name        = "8080"
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "api_internal" {
  metadata {
    name = "api-internal"
    labels = {
      "gropius.app" = "api-internal"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "gropius.app" = "api-internal"
      }
    }

    template {
      metadata {
        labels = {
          "gropius.app" = "api-internal"
        }
      }

      spec {
        container {
          name  = "api-internal"
          image = "ghcr.io/ccims/gropius-api-internal:main"

          env {
            name  = "GROPIUS_API_INTERNAL_API_TOKEN"
            value = random_password.internal_api_token.result
          }

          env {
            name  = "GROPIUS_CORE_CREATE_INDICES_ON_STARTUP"
            value = "false"
          }

          env {
            name  = "LOGGING_LEVEL_ROOT"
            value = "ERROR"
          }

          env {
            name  = "SPRING_NEO4J_AUTHENTICATION_PASSWORD"
            value = random_password.neo4j_password.result
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
            exec {
              command = ["wget", "http://localhost:8080/graphiql", "||", "exit", "1"]
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
