# ============================================================
# S3 — Bucket para alojar los archivos estáticos del sitio
# Tag Name: "Web+s3" según convención del proyecto
# ============================================================

# ── Bucket principal ──────────────────────────────────────
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name = "Web+s3" # EDITAR: convención Name del proyecto
  }
}

# ── Bloquear TODO acceso público directo al bucket ────────
# El acceso se hace SOLO a través de CloudFront (OAC)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Versionado (opcional pero recomendado para rollbacks) ─
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled" # EDITAR: "Suspended" para desactivar
  }
}

# ── Cifrado en reposo ──────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ── Política de bucket: permite acceso SOLO desde CloudFront ─
# Usa OAC (Origin Access Control) — método moderno, reemplaza OAI
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_cloudfront_policy.json

  # Espera a que el bloqueo de acceso público esté aplicado antes
  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Documento de política IAM en HCL (más legible que JSON raw)
data "aws_iam_policy_document" "s3_cloudfront_policy" {
  statement {
    sid    = "AllowCloudFrontOACAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.website.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      # Solo el CloudFront de ESTE proyecto puede leer el bucket
      values = [aws_cloudfront_distribution.website.arn]
    }
  }
}
