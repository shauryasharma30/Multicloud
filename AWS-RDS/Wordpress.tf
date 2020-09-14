provider "kubernetes" {
    config_context_cluster   = "minikube"
}
resource "kubernetes_deployment" "WordPress" {
  metadata {
    name = "wordpress"
  }
  spec {

    replicas = 3
    
    selector{
    match_labels = {
      dc = "IN"
      env = "Testing"
      App = "wordpress"
    }
    match_expressions {
      key = "env"
      operator = "In"
      values = ["Testing" , "wordpress"]
    }
  }
   template {
        metadata {
         labels = {
      
      dc = "IN"
      env = "Testing" 
      App = "wordpress"
    }
        }

      spec {
        container {
          image = "wordpress:4.8-apache"
          name  = "wpress"

        }
      }
    }
}
}
resource "kubernetes_service" "service" {
  metadata {
    name = "loadbalancer"
  }
  spec {
    selector = {
      App = kubernetes_deployment.WordPress.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30003 
      port        = 80
      target_port = 80
    }
    type = "NodePort"
} 
}
