resource "kubernetes_config_map_v1" "app_config" {
  metadata {
    name      = "sre-lab-config"
    namespace = var.namespace
  }

  data = {
    APP_ENV   = var.app_env
    LOG_LEVEL = var.log_level
  }
}

resource "kubernetes_resource_quota_v1" "namespace_quota" {
  metadata {
    name      = "sre-lab-quota"
    namespace = var.namespace
  }

  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "20"
    }
  }
}

resource "kubernetes_limit_range_v1" "default_limits" {
  metadata {
    name      = "sre-lab-limit-range"
    namespace = var.namespace
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = "500m"
        memory = "256Mi"
      }

      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}
