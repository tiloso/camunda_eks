resource "kubernetes_namespace" "camunda" {
  metadata {
    name = "camunda"
  }
}

resource "helm_release" "camunda" {
  namespace  = kubernetes_namespace.camunda.metadata.0.name
  name       = "camunda"
  repository = "https://helm.camunda.io"
  chart      = "camunda-platform"
  version    = "8.1.6"

  values = [templatefile("${path.module}/templates/camunda-values.tftpl", {
    domain                = var.domain,
    main_certificate_arn  = aws_acm_certificate.main.arn,
    zeebe_certificate_arn = aws_acm_certificate.zeebe.arn,
    first_user_username   = var.camunda_first_user_username,
    first_user_password   = var.camunda_first_user_password,
    first_user_email      = var.camunda_first_user_email,
    first_user_firstname  = var.camunda_first_user_firstname,
    first_user_lastname   = var.camunda_first_user_lastname,
  })]

  wait = true

  depends_on = [
    kubernetes_storage_class.gp3,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "19.3.3"

  set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "gp3"
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = "gp3"
  }

  wait = true

  depends_on = [kubernetes_storage_class.gp3]
}

# https://docs.camunda.io/docs/self-managed/platform-deployment/helm-kubernetes/platforms/amazon-eks/#eks-cluster-specification
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = "true"
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "kubernetes_annotations" "default-storageclass" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

data "kubernetes_ingress_v1" "camunda_platform" {
  metadata {
    name      = "camunda-camunda-platform"
    namespace = "camunda"
  }

  depends_on = [helm_release.camunda]
}

data "aws_lb_hosted_zone_id" "main" {}

resource "aws_route53_record" "a_camunda_platform" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = data.kubernetes_ingress_v1.camunda_platform.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb_hosted_zone_id.main.id
    evaluate_target_health = true
  }
}

data "kubernetes_ingress_v1" "camunda_zeebe" {
  metadata {
    name      = "camunda-zeebe-gateway"
    namespace = "camunda"
  }

  depends_on = [helm_release.camunda]
}

resource "aws_route53_record" "a_camunda_zeebe" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "zeebe.${var.domain}"
  type    = "A"
  alias {
    name                   = data.kubernetes_ingress_v1.camunda_zeebe.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb_hosted_zone_id.main.id
    evaluate_target_health = true
  }
}
