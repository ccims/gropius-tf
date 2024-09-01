resource "random_password" "sync_api_secret" {
  length  = 20
  special = true
}

resource "random_password" "internal_api_token" {
  length  = 20
  special = true
}

resource "kubernetes_secret" "login_service_secrets" {
  metadata {
    name      = "login-service-secrets"
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  data = {
    sync_api_secret                = random_password.sync_api_secret.result
    internal_api_token             = random_password.internal_api_token.result
    gropius_default_user_post_data = "{\"password\":\"${var.admin_password}\"}"
  }
}

resource "tls_private_key" "oauth_key" {
  count = var.generate_login_service_keys ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "login_specific_key" {
  count = var.generate_login_service_keys ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "kubernetes_secret" "login_service_keys" {
  count = var.generate_login_service_keys ? 1 : 0

  metadata {
    name      = "login-service-keys"
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  data = {
    oauth_public_key           = base64encode(tls_private_key.oauth_key[0].public_key_pem)
    oauth_private_key          = base64encode(tls_private_key.oauth_key[0].private_key_pem)
    login_specific_public_key  = base64encode(tls_private_key.login_specific_key[0].public_key_pem)
    login_specific_private_key = base64encode(tls_private_key.login_specific_key[0].private_key_pem)
  }
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
            name = "GROPIUS_DEFAULT_USER_POST_DATA"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.login_service_secrets.metadata[0].name
                key  = "gropius_default_user_post_data"
              }
            }
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
            name = "GROPIUS_INTERNAL_BACKEND_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.login_service_secrets.metadata[0].name
                key  = "internal_api_token"
              }
            }
          }

          env {
            name  = "GROPIUS_LOGIN_DATABASE_HOST"
            value = "postgres-db-postgresql"
          }

          env {
            name = "GROPIUS_LOGIN_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_password_secret.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "GROPIUS_LOGIN_SYNC_API_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.login_service_secrets.metadata[0].name
                key  = "sync_api_secret"
              }
            }
          }

          env {
            name = "GROPIUS_OAUTH_PUBLIC_KEY"
            value_from {
              secret_key_ref {
                name = "login-service-keys"
                key  = "oauth_public_key"
              }
            }
          }

          env {
            name = "GROPIUS_LOGIN_SPECIFIC_PUBLIC_KEY"
            value_from {
              secret_key_ref {
                name = "login-service-keys"
                key  = "login_specific_public_key"
              }
            }
          }

          env {
            name = "GROPIUS_OAUTH_PRIVATE_KEY"
            value_from {
              secret_key_ref {
                name = "login-service-keys"
                key  = "oauth_private_key"
              }
            }
          }

          env {
            name = "GROPIUS_LOGIN_SPECIFIC_PRIVATE_KEY"
            value_from {
              secret_key_ref {
                name = "login-service-keys"
                key  = "login_specific_private_key"
              }
            }
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
