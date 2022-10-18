terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.29.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "self" {}

variable "prefix" {
}