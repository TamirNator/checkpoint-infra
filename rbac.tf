resource "kubernetes_role_binding" "dev_role_binding" {
  metadata {
    name      = "eks-dev-role-binding"
    namespace = "dev"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.dev_role.metadata[0].name
  }
  subject {
    kind      = "User" 
    name      = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/GitHubOIDC"
    api_group = "rbac.authorization.k8s.io"
    namespace = "dev"
  }
    subject {
    kind      = "User" 
    name      = "arn:aws:iam::${data.aws_caller_identity.current.id}:user/tamirna811"
    api_group = "rbac.authorization.k8s.io"
    namespace = "dev"
  }
}

resource "kubernetes_role" "dev_role" {
  metadata {
    name = "eks-dev-role"
    namespace = "dev"
  }
  rule {
    api_groups     = [""]
    resources      = ["pods", "secrets", "serviceaccounts", "services"]
    verbs          = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}