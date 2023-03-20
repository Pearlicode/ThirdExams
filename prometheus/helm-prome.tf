terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }

    kubernetes = {
        version = ">= 2.0.0"
        source = "hashicorp/kubernetes"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}


data "aws_eks_cluster" "demo" {
  name = "demo"
}
data "aws_eks_cluster_auth" "demo_auth" {
  name = "demo_auth"
}


provider "aws" {
  region     = "us-east-1"
}

provider "helm" {
    kubernetes {
       #host                   = data.aws_eks_cluster.demo.endpoint
      # cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
       #token                  = data.aws_eks_cluster_auth.demo_auth.token
      config_path = "~/.kube/config"
    }
}

provider "kubernetes" {
  #host                   = data.aws_eks_cluster.demo.endpoint
 # cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
  #token                  = data.aws_eks_cluster_auth.demo_auth.token
 #  version          = "2.16.1"
  config_path = "~/.kube/config"
}

provider "kubectl" {
   load_config_file = false
   host                   = data.aws_eks_cluster.demo.endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
   token                  = data.aws_eks_cluster_auth.demo_auth.token
    config_path = "~/.kube/config"
}
ubuntu@ip-172-31-13-4:~/prometheus$ ls
helm-prome.tf  providers-prome.tf  terraform.tfstate  terraform.tfstate.backup  values.yaml
ubuntu@ip-172-31-13-4:~/prometheus$ cat helm-prome.tf 
data "aws_eks_node_group" "eks-node-group" {
  cluster_name = "demo"
  node_group_name = "private-nodes"
}

resource "time_sleep" "wait_for_kubernetes" {

    depends_on = [
        data.aws_eks_cluster.demo
    ]

    create_duration = "20s"
}

resource "kubernetes_namespace" "kube-namespace" {
  depends_on = [data.aws_eks_node_group.eks-node-group, time_sleep.wait_for_kubernetes]
  metadata {
    
    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.kube-namespace, time_sleep.wait_for_kubernetes]
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.kube-namespace.id
  create_namespace = true
  version    = "45.7.1"
  values = [
    file("values.yaml")
  ]
  timeout = 2000
  

set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  # You can provide a map of value using yamlencode. Don't forget to escape the last element after point in the name
  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}