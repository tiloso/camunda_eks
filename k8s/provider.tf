provider "aws" {
  profile = "default"
  region  = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

data "tls_certificate" "main" {
  url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "aws_iam_openid_connect_provider" "main" {
  url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}
