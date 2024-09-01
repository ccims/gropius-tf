variable "admin_password" {
  type        = string
  description = "The password for the admin user"
  default     = "admin"
}

variable "namespace" {
  type        = string
  description = "The k8s namespace to deploy the application in"
  default     = "gropius"
}

variable "gropius_endpoint" {
  type        = string
  description = "The host url of gropius frontend"
  default     = "http://localhost:4200"
}

variable "gropius_version" {
  type        = string
  description = "The version of gropius to deploy"
  default     = "latest"
}

variable "enable_ingress" {
  type        = bool
  description = "Whether to enable the ingress, only relevant if gropius_endpoint starts with https://"
  default     = false
}

variable "generate_login_service_keys" {
  type        = bool
  description = "If true, the two private public key pairs for the login service will be generated and stored in k8s secrets. If false, this secret must be created manually (see README)."
  default     = true
}

variable "sync_github" {
  type        = bool
  description = "Whether to sync the github repositories"
  default     = false
}

variable "sync_jira" {
  type        = bool
  description = "Whether to sync the jira issues"
  default     = false
}

variable "storage_class" {
  type        = string
  description = "The storage class to use for all databases"
  nullable    = true
  default     = null
}

variable "kubeconfig" {
  type        = string
  description = "The kubeconfig file to use for kubectl"
  default     = "./kubeconfig.yaml"
}
