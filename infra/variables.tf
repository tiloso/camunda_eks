variable "domain" {
  description = "Domain of the Camunda platform"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "main"
}

variable "cluster_k8s_version" {
  description = "Version of the Kubernetes cluster"
  type        = string
  default     = ""
}

variable "cluster_public_access_cidrs" {
  description = "CIDRS which are being granted access to the public Kubernetes API endpoint"
  type        = list(string)
  default     = []
}

variable "cluster_addon_version_coredns" {
  description = "Version of the CoreDNS Kubernetes addon"
  type        = string
  default     = ""
}

variable "cluster_addon_version_ebs_csi_driver" {
  description = "Version of the EBS CSI driver Kubernetes addon"
  type        = string
  default     = ""
}

variable "cluster_addon_version_kube_proxy" {
  description = "Version of the kube-proxy Kubernetes addon"
  type        = string
  default     = ""
}

variable "cluster_addon_version_vpc_cni" {
  description = "Version of the VPC CNI Kubernetes addon"
  type        = string
  default     = ""
}

variable "cluster_node_groups_per_subnet_release_version" {
  description = "Release version of the Kubernetes cluster node groups; available listed at https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md"
  type        = string
  default     = ""
}

variable "cluster_node_groups_per_subnet_instance_type" {
  description = "Instance type of the Kubernetes cluster node groups"
  type        = list(string)
  default     = ["m5a.xlarge"]
}

variable "cluster_node_groups_per_subnet_disk_size" {
  description = "Disk size of the Kubernetes cluster node groups"
  type        = number
  default     = 40
}

variable "cluster_node_groups_per_subnet_desired_size" {
  description = "Desired size of the Kubernetes cluster node groups"
  type        = number
  default     = 2
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "main"
}

variable "vpc_cidr" {
  description = "CIDR of the VPC"
  type        = string
  default     = "172.20.0.0/16"
}

variable "subnets_public" {
  description = "Availability Zone and CIDRS of the public subnets"
  type        = map(string)
  default = {
    a = "172.20.0.0/22"
    b = "172.20.4.0/22"
    # c = "172.20.8.0/22"
  }
}

variable "subnets_private" {
  description = "Availability Zone and CIDRS of the private subnets"
  type        = map(string)
  default = {
    a = "172.20.32.0/19"
    b = "172.20.64.0/19"
    # c = "172.20.96.0/19"
  }
}
