resource "random_password" "sync_api_secret" {
  length  = 20
  special = true
}

resource "tls_private_key" "oauth_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "login_specific_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "oauth_public_key_pem" {
  value = tls_private_key.oauth_key.public_key_pem
}

output "login_specific_public_key_pem" {
  value = tls_private_key.login_specific_key.public_key_pem
}


resource "kubernetes_service" "login_service" {
  metadata {
    name = "login-service"
    labels = {
      "gropius.app" = "login-service"
    }
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  spec {
    port {
      name        = "3000"
      port        = 3000
      target_port = 3000
    }

    selector = {
      "gropius.app" = "login-service"
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
          name              = "login-service"
          image             = "ghcr.io/ccims/gropius-login-service:${var.gropius_version}"
          image_pull_policy = "Always"
          command           = ["/bin/sh", "-c", "npx typeorm migration:run -d dist/migrationDataSource.config.js && sleep 10 && node dist/main.js"]

          port {
            container_port = 3000
          }

          env {
            name  = "GROPIUS_ACCESS_TOKEN_EXPIRATION_TIME_MS"
            value = "600000"
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
            name  = "GROPIUS_ENDPOINT"
            value = var.gropius_endpoint
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
            name  = "GROPIUS_LOGIN_SYNC_API_SECRET"
            value = random_password.sync_api_secret.result
          }

          env {
            name  = "GROPIUS_OAUTH_PUBLIC_KEY"
            value = base64encode(tls_private_key.oauth_key.public_key_pem)
          }

          env {
            name  = "GROPIUS_LOGIN_SPECIFIC_PUBLIC_KEY"
            value = base64encode(tls_private_key.login_specific_key.public_key_pem)
          }

          env {
            name  = "GROPIUS_OAUTH_PRIVATE_KEY"
            value = base64encode(tls_private_key.oauth_key.private_key_pem)
          }

          env {
            name  = "GROPIUS_LOGIN_SPECIFIC_PRIVATE_KEY"
            value = base64encode(tls_private_key.login_specific_key.private_key_pem)
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          liveness_probe {
            http_get {
              port = "3000"
              path = "/auth/api/login/strategy"
            }
            failure_threshold     = 20
            initial_delay_seconds = 60
            period_seconds        = 5
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}
