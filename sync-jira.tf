resource "kubernetes_deployment" "sync_jira" {
  count = var.sync_jira ? 1 : 0

  metadata {
    name = "sync-jira"
    labels = {
      "gropius.app" = "sync-jira"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "gropius.app" = "sync-jira"
      }
    }

    template {
      metadata {
        labels = {
          "gropius.app" = "sync-jira"
        }
      }

      spec {
        container {
          name              = "sync-jira"
          image             = "ghcr.io/ccims/gropius-jira:${var.gropius_version}"
          image_pull_policy = "Always"


          env {
            name  = "GROPIUS_CORE_CREATE_INDICES_ON_STARTUP"
            value = "false"
          }

          env {
            name  = "GRAPHGLUE_CORE_USE_NEO4J_PLUGIN"
            value = "true"
          }

          env {
            name  = "LOGGING_LEVEL_ROOT"
            value = "INFO"
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

          env {
            name  = "SPRING_DATA_MONGODB_HOST"
            value = "mongodb"
          }

          env {
            name  = "SPRING_DATA_MONGODB_PORT"
            value = "27017"
          }

          env {
            name  = "SPRING_DATA_MONGODB_DATABASE"
            value = "gropius"
          }

          env {
            name  = "SPRING_DATA_MONGODB_USERNAME"
            value = "root"
          }

          env {
            name  = "SPRING_DATA_MONGODB_PASSWORD"
            value = random_password.mongo_root_password.result
          }

          env {
            name  = "GROPIUS_SYNC_LOGIN_SERVICE_BASE"
            value = "http://login-service:3000"
          }

          env {
            name  = "GROPIUS_SYNC_API_SECRET"
            value = random_password.sync_api_secret.result
          }

          liveness_probe {
            exec {
              command = ["true"]
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
