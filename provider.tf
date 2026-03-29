terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # EDITAR: Descomenta y configura si usas Terraform Cloud o un backend S3
  # backend "s3" {
  #   bucket  = "mi-tfstate-bucket"
  #   key     = "webandres/terraform.tfstate"
  #   region  = "eu-west-1"
  #   encrypt = true
  # }
}

# Provider principal — región donde vive el bucket S3
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Proyecto    = "WebAndres"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Provider secundario — us-east-1 es OBLIGATORIO para certificados ACM
# que se usen con CloudFront (restricción de AWS, no de Terraform)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Proyecto    = "WebAndres"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
