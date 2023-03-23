variable "environment_suffix" {
  type        = string
  description = "procure le suffixe indiquant l'env. cible"
}

variable "project_name" {
  type = string
}

variable "api_port" {
  type = number
}

variable "access_token_expiry" {
  type = string
}

variable "refresh_token_expiry" {
  type = string
}

variable "refresh_token_cookie_name" {
  type = string
}
