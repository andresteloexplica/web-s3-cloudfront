# ============================================================
# VARIABLES
# EDITAR: Cambia los valores default o pásalos con -var / .tfvars
# ============================================================

variable "aws_region" {
  description = "Región de AWS donde se crea el bucket S3"
  type        = string
  default     = "eu-south-2"
}

variable "environment" {
  description = "Entorno (prod, staging, dev)"
  type        = string
  default     = "prod"
}

# EDITAR: Nombre único global para el bucket S3
# Los nombres de bucket deben ser únicos en todo AWS
variable "bucket_name" {
  description = "Nombre del bucket S3 (debe ser globalmente único en AWS)"
  type        = string
  default     = "webandres-website" # EDITAR: pon tu nombre único aquí
}

variable "domain_name" {
  description = "Dominio raíz del sitio (sin www)"
  type        = string
  default     = "andresexplica.com"
}

variable "cloudfront_price_class" {
  description = "Clase de precio CloudFront: PriceClass_100 (US+EU), PriceClass_200 (+Asia), PriceClass_All"
  type        = string
  default     = "PriceClass_100" # EDITAR: PriceClass_All para cobertura global total

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Valor válido: PriceClass_100 | PriceClass_200 | PriceClass_All"
  }
}

variable "default_root_object" {
  description = "Archivo por defecto que sirve CloudFront"
  type        = string
  default     = "index.html"
}
