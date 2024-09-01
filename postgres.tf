resource "random_password" "postgres_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "postgres_password_secret" {
  metadata {
    name      = "postgres-password"
    namespace = kubernetes_namespace.gropius.metadata[0].name
  }

  data = {
    password = random_password.postgres_password.result
  }
}

resource "helm_release" "postgres_db" {
  name       = "postgres-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gropius.metadata[0].name

  set {
    name  = "global.postgresql.auth.database"
    value = "gropius"
  }

  dynamic "set" {
    for_each = var.storage_class != null ? [var.storage_class] : []
    content {
      name  = "global.storageClass"
      value = set.value
    }
  }

  set {
    name  = "postgres.auth.enablePostgresUser"
    value = "false"
  }

  set {
    name  = "global.postgresql.auth.username"
    value = "postgres"
  }

  set {
    name  = "global.postgresql.auth.password"
    value = random_password.postgres_password.result
  }
}
