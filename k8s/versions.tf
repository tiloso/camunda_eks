terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.17.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }

  required_version = ">= 1.3.0"
}
