resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Cluster"
  }

  set {
    name  = "controller.replicaCount"
    value = 1
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
}

resource "helm_release" "grafana" {
  name            = "grafana"
  chart           = "grafana"
  repository      = "https://grafana.github.io/helm-charts"
  namespace       = "monitoring"
  create_namespace = true

  values = [file("${path.module}/manifests/grafana-values.yaml")]

  depends_on = [module.eks]
}

resource "helm_release" "prometheus" {
  name            = "kube-prometheus-stack"
  chart           = "kube-prometheus-stack"
  repository      = "https://prometheus-community.github.io/helm-charts"
  namespace       = "monitoring"

  values = [file("${path.module}/manifests/prometheus-values.yaml")]

  depends_on = [module.eks, helm_release.grafana]
}


data "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = "tamir-github-token"
}

resource "kubectl_manifest" "argocd_git_secret" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: argocd-git-creds
  namespace: argocd
type: Opaque
stringData:
  username: ${jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["username"]}
  password: ${jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["token"]}
YAML
depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: counter-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "https://github.com/TamirNator/checkpoint.git"
    path: deploy/app
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
    syncOptions:
      - CreateNamespace=true
YAML
  depends_on = [ helm_release.argocd ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true

  values = [file("${path.module}/manifests/argocd-values.yaml")]

  set {
    name  = "configs.repositories.checkpoint.url"
    value = "https://github.com/TamirNator/checkpoint.git"
  }

  set {
    name  = "configs.repositories.checkpoint.username"
    value = jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["username"]
  }

  set {
    name  = "configs.repositories.checkpoint.password"
    value = jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["token"]
  }
}