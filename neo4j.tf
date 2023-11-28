resource "random_password" "neo4j_password" {
  length  = 20
  special = true
}

resource "helm_release" "neo4j_db" {
  name       = "neo4j-db"
  repository = "https://helm.neo4j.com/neo4j"
  chart      = "neo4j"
  namespace  = kubernetes_namespace.gropius.metadata[0].name

  set {
    name  = "neo4j.edition"
    value = "community"
  }

  set {
    name  = "neo4j.name"
    value = "gropius"
  }

  set {
    name  = "neo4j.password"
    value = random_password.neo4j_password.result
  }

  set {
    name  = "volumes.data.mode"
    value = "defaultStorageClass"
  }

  set {
    name  ="readinessProbe.failureThreshold"
    value = "20"
  }

  set {
    name  ="readinessProbe.timeoutSeconds"
    value = "100"
  }

  set {
    name  ="readinessProbe.periodSeconds"
    value = "50"
  }

  set {
    name  ="livenessProbe.failureThreshold"
    value = "40"
  }

  set {
    name  ="livenessProbe.timeoutSeconds"
    value = "100"
  }

  set {
    name  ="livenessProbe.periodSeconds"
    value = "50"
  }

  set {
    name  ="startupProbe.failureThreshold"
    value = "1000"
  }

  set {
    name  ="startupProbe.periodSeconds"
    value = "20"
  }

  set {
    name = "services.neo4j.enabled"
    value = "false"
  }
}