variable "domain" {
  description = "Domain of the Camunda platform"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "main"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "camunda_first_user_username" {
  description = "Username of the first user in Camunda identity"
  type        = string
  default     = ""
}

variable "camunda_first_user_password" {
  description = "Password of the first user in Camunda identity"
  type        = string
  sensitive   = true
  default     = ""
}

variable "camunda_first_user_email" {
  description = "Email of the first user in Camunda identity"
  type        = string
  default     = ""
}

variable "camunda_first_user_firstname" {
  description = "Firstname of the first user in Camunda identity"
  type        = string
  default     = ""
}

variable "camunda_first_user_lastname" {
  description = "Lastname of the first user in Camunda identity"
  type        = string
  default     = ""
}
