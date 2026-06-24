variable "namespace" {
  description = "Kubernetes namespace for the SRE Lab application"
  type        = string
  default     = "sre-lab"
}

variable "app_env" {
  description = "Application environment value"
  type        = string
  default     = "local"
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "debug"
}
