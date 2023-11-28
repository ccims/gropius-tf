resource "random_uuid" "default_auth_client_id" {

}

resource "random_password" "login_jwt_secret" {
  length  = 100
  special = false
}

resource "random_password" "sync_api_secret" {
  length  = 20
  special = true
}

resource "kubernetes_service" "login_service" {
  metadata {
    name = "login-service"
    labels = {
      "gropius.app" = "login-service"
    }
  }

  spec {
    port {
      name        = "3000"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "login_service" {
  metadata {
    name = "login-service"
    labels = {
      "gropius.app" = "login-service"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "gropius.app" = "login-service"
      }
    }

    template {
      metadata {
        labels = {
          "gropius.app" = "login-service"
        }
      }

      spec {
        container {
          name  = "login-service"
          image = "ghcr.io/ccims/gropius-login-service:main"

          env {
            name  = "GROPIUS_ACCESS_TOKEN_EXPIRATION_TIME_MS"
            value = "600000"
          }

          env {
            name  = "GROPIUS_DEFAULT_AUTH_CLIENT_ID"
            value = random_uuid.default_auth_client_id.result
          }

          env {
            name  = "GROPIUS_DEFAULT_AUTH_CLIENT_NAME"
            value = "initial-client"
          }

          env {
            name  = "GROPIUS_DEFAULT_STRATEGY_INSTANCE_CONFIG"
            value = "{}"
          }

          env {
            name  = "GROPIUS_DEFAULT_STRATEGY_INSTANCE_NAME"
            value = "userpass-local"
          }

          env {
            name  = "GROPIUS_DEFAULT_STRATEGY_INSTANCE_TYPE"
            value = "userpass"
          }

          env {
            name  = "GROPIUS_DEFAULT_USER_DISPLAYNAME"
            value = "System-Admin"
          }

          env {
            name  = "GROPIUS_DEFAULT_USER_POST_DATA"
            value = "{\"password\":\"${var.admin_password}\"}"
          }

          env {
            name  = "GROPIUS_DEFAULT_USER_STRATEGY_INSTANCE_NAME"
            value = "userpass-local"
          }

          env {
            name  = "GROPIUS_DEFAULT_USER_USERNAME"
            value = "admin"
          }

          env {
            name  = "GROPIUS_INTERNAL_BACKEND_ENDPOINT"
            value = "http://api-internal:8080/graphql"
          }

          env {
            name  = "GROPIUS_INTERNAL_BACKEND_JWT_SECRET"
            value = random_password.public_jwt_secret.result
          }

          env {
            name  = "GROPIUS_INTERNAL_BACKEND_TOKEN"
            value = random_password.internal_api_token.result
          }

          env {
            name  = "GROPIUS_LOGIN_DATABASE_HOST"
            value = "postgres-db-postgresql"
          }

          env {
            name  = "GROPIUS_LOGIN_DATABASE_PASSWORD"
            value = random_password.postgres_password.result
          }

          env {
            name  = "GROPIUS_LOGIN_SPECIFIC_JWT_SECRET"
            value = random_password.login_jwt_secret
          }

          env {
            name  = "GROPIUS_LOGIN_SYNC_API_SECRET"
            value = random_password.sync_api_secret
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          liveness_probe {
            exec {
              command = ["wget", "http://localhost:3000/login/strategy", "||", "exit", "1"]
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
