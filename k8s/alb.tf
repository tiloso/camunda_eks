# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
data "aws_iam_policy_document" "alb_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.main.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "alb" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/files/alb_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb" {
  policy_arn = aws_iam_policy.alb.arn
  role       = aws_iam_role.alb.name
}

resource "aws_iam_role" "alb" {
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role_policy.json
  name               = "AmazonEKSLoadBalancerControllerRole"
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.7"

  namespace = "kube-system"

  values = [
    jsonencode({
      clusterName       = var.cluster_name
      region            = var.region
      enableCertManager = false
      serviceAccount = {
        create = true
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb.arn
        }
      }
    })
  ]

  wait       = true
  depends_on = [aws_iam_role_policy_attachment.alb]
}
