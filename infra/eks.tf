resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_k8s_version

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
  ]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = [for az in keys(var.subnets_public) : aws_subnet.main_public[az].id]
    public_access_cidrs     = var.cluster_public_access_cidrs
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_main.arn
    }
  }

  tags = {
    cluster = var.cluster_name
  }
}

resource "aws_kms_key" "eks_main" {
  description = "eks ${var.cluster_name} encryption key"
}

resource "aws_eks_addon" "main_vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = var.cluster_addon_version_vpc_cni
  service_account_role_arn = aws_iam_role.eks_cni_role.arn
  depends_on               = [aws_iam_role_policy_attachment.eks_cni_role]
}

resource "aws_eks_addon" "main_coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = var.cluster_addon_version_coredns
}

resource "aws_eks_addon" "main_kube_proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = var.cluster_addon_version_kube_proxy
}

resource "aws_eks_addon" "main_ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.cluster_addon_version_ebs_csi_driver
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
  depends_on               = [aws_iam_role_policy_attachment.ebs_csi_driver_role]
}


data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}


resource "aws_eks_node_group" "main" {
  for_each = var.subnets_private

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  ami_type        = "AL2_x86_64"
  release_version = var.cluster_node_groups_per_subnet_release_version
  instance_types  = var.cluster_node_groups_per_subnet_instance_type
  disk_size       = var.cluster_node_groups_per_subnet_disk_size


  node_role_arn = aws_iam_role.eks_node_role.arn
  subnet_ids    = [aws_subnet.main_private[each.key].id]

  labels = {
    nodegroup = "${var.cluster_name}-${each.key}"
  }

  tags = {
    nodegroup = "${var.cluster_name}-${each.key}"
  }

  scaling_config {
    desired_size = var.cluster_node_groups_per_subnet_desired_size
    max_size     = var.cluster_node_groups_per_subnet_desired_size + 1
    min_size     = var.cluster_node_groups_per_subnet_desired_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecr_read_only_policy,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
  ]
}


resource "aws_iam_role" "eks_cluster_role" {
  name        = "eksClusterRole"
  description = "EKS cluster role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name        = "eksNodeRole"
  description = "EKS node role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

data "aws_iam_policy_document" "eks_cni_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.main.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cni_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_cni_role.json
  name               = "eksCNIRole"
}

resource "aws_iam_role_policy_attachment" "eks_cni_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cni_role.name
}


data "aws_iam_policy_document" "ebs_csi_driver_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.main.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_role.json
  name               = "eksEBSCSIDriverRole"
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}
