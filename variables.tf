variable "project" {
  description = "Short project name used as a prefix for every resource name"
  type        = string
  default     = "social"
}

variable "environment" {
  description = "Environment name: dev, staging, prod — keep separate state per environment"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "container_apps_subnet_prefix" {
  description = "Must be at least /23 — this is the Container Apps environment's hard minimum"
  type        = string
  default     = "10.0.0.0/23"
}

variable "postgres_subnet_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "postgres_admin_username" {
  description = "PostgreSQL-native admin login — the break-glass account, not used by services"
  type        = string
  default     = "pgadmin"
}

variable "postgres_sku_name" {
  description = "Compute tier. B_Standard_B1ms is cheapest for early stage; scale up without a rebuild later."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "entra_admin_object_id" {
  description = "Object ID of the Entra ID user or group to set as the Postgres Entra administrator"
  type        = string
}

variable "entra_admin_login" {
  description = "UPN of the Entra admin user, or display name if pointing at a group"
  type        = string
}

variable "entra_admin_principal_type" {
  description = "\"User\" or \"Group\" — use a Group if more than one teammate needs admin access"
  type        = string
  default     = "User"
}
