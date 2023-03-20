resource "kubernetes_deployment" "kube-voting-deployment" {
  metadata {
    name      = "azure-vote-back"
    namespace =  kubernetes_namespace.kube-namespace.id
    labels = {
      name = "demo-voting-app"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "azure-vote-back"
      }
    }
    template {
      metadata {
        name =  "azure-vote-back"
        labels = {
          app = "azure-vote-back"
        }
      }
      spec {
        container {
          image = "mcr.microsoft.com/oss/bitnami/redis:6.0.8"
          name  = "azure-vote-back"

          env {
            name = "ALLOW_EMPTY_PASSWORD"
            value = "yes"
          }

      port {
        container_port = 6379
        name = "redis"
      }
      }
    }
  }
}
}



# Create kubernetes  for cart service

resource "kubernetes_service" "kube-voting-service" {
  metadata {
    name      = "azure-vote-back"
    namespace =  kubernetes_namespace.kube-namespace.id

  }
  spec {
    selector = {
      app = "azure-vote-back"
    }
    port {
      port        = 6379
      target_port = 6379
    }
  }
}


# newwwwwwwww

resource "kubernetes_deployment" "kube-voting-backend-deployment" {
  metadata {
    name      = "azure-vote-front"
    namespace =  kubernetes_namespace.kube-namespace.id
    labels = {
      name = "azure-vote-front"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "azure-vote-front"
      }
    }
    strategy {
        rolling_update {
            max_surge = 1
            max_unavailable = 1
        }
    }
    min_ready_seconds = 5

    template {
      metadata {
        name =  "azure-vote-back"
        labels = {
          app = "azure-vote-front"
        }
      }
      spec {
        node_selector = {
        "beta.kubernetes.io/os" = "linux"
      }
        container {
          image = "mcr.microsoft.com/azuredocs/azure-vote-front:v1"
          name  = "azure-vote-front"

      port {
        container_port = 80
      }
       resources {
        limits = {
          cpu = "500m"
        }
        requests = {
          cpu = "250m"
        }
      }
      env {
        name = "REDIS"
        value = "azure-vote-back"
      }
      }
    }
  }
}
}



# Create kubernetes  for cart service

resource "kubernetes_service" "kube-frontend-service" {
  metadata {
    name      = "azure-vote-front"
    namespace =  kubernetes_namespace.kube-namespace.id
   /*  annotations = {
        prometheus.io/scrape: "true"
    } */

  }
  spec {
    selector = {
      app = "azure-vote-front"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}