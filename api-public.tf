resource "random_password" "public_jwt_secret" {
  length = 100
  special = false
}

resource "kubernetes_service" "api_public" {
  metadata {
    name = "api-public"
    labels = {
      "gropius.app" = "api-public"
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
          name  = "api-public"
          image = "ghcr.io/ccims/gropius-api-public:main"

          env {
            name  = "GROPIUS_API_PUBLIC_JWT_SECRET"
            value = random_password.public_jwt_secret.result
          }

          env {
            name  = "GROPIUS_CORE_CREATE_INDICES_ON_STARTUP"
            value = "true"
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
