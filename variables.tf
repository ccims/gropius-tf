variable "admin_password" {
  type        = string
  description = "The password for the admin user"
  default     = "admin"
}

variable "gropius_endpoint" {
  type        = string
  description = "The host url of gropius frontend"
  default     = "http://localhost:4200"
}

variable "enable_ingress" {
  type        = bool
  description = "Whether to enable the ingress, only relevant if gropius_endpoint starts with https://"
  default     = false
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
  nullable = true
  default = null
}

variable "kubeconfig" {
  type        = string
  description = "The kubeconfig file to use for kubectl"
  default = "./kubeconfig.yaml"
}