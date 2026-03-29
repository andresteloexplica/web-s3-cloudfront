# ============================================================
# CLOUDFRONT — Distribución CDN + Origin Access Control
# Tag Name: "Web+cloudfront" según convención del proyecto
# ============================================================

# ── Origin Access Control (OAC) ───────────────────────────
# Método moderno para que CloudFront acceda al bucket S3 de
# forma segura sin hacer el bucket público. Reemplaza al OAI legado.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "oac-${var.bucket_name}"
  description                       = "OAC para Web ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  # Nota: aws_cloudfront_origin_access_control no soporta tags en la API de AWS
}

# ── Distribución CloudFront ────────────────────────────────
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "WebAndres - Sitio estático" # EDITAR: descripción
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class
  http_version        = "http2and3" # HTTP/2 + HTTP/3 (QUIC)

  aliases = [var.domain_name, "www.${var.domain_name}"]

  # ── Origen: el bucket S3 ──────────────────────────────
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id

    # Añade headers de seguridad opcionales al origen
    # origin_shield { enabled = false; origin_shield_region = var.aws_region }
  }

  # ── Comportamiento de caché por defecto ───────────────
  default_cache_behavior {
    target_origin_id       = "s3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https" # Fuerza HTTPS

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress = true # Gzip + Brotli automático

    # Política de caché gestionada por AWS: CachingOptimized
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    # Reescritura de URLs: /blog/ → /blog/index.html
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_index.arn
    }
  }

  # ── Respuestas de error personalizadas ────────────────
  # Redirige 403/404 a index.html → necesario para SPAs con rutas client-side
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # ── Certificado SSL ────────────────────────────────────
  # Referencia aws_acm_certificate_validation (no el cert directamente)
  # para garantizar que CloudFront solo se crea tras la validación completa.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only"       # requerido con ACM propio
    minimum_protocol_version = "TLSv1.2_2021"   # deshabilita TLS < 1.2
  }

  # ── Restricciones geo ──────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = "none" # EDITAR: "whitelist" o "blacklist" si lo necesitas
      # locations      = ["ES", "MX", "AR"]  # Ejemplo: solo España, México, Argentina
    }
  }

  # ── Logging (opcional) ────────────────────────────────
  # EDITAR: Descomenta para activar logs de acceso en otro bucket S3
  # logging_config {
  #   include_cookies = false
  #   bucket          = "mi-logs-bucket.s3.amazonaws.com"
  #   prefix          = "webandres-cf/"
  # }

  tags = {
    Name = "Web+cloudfront" # EDITAR: convención Name del proyecto
  }

}

# ── CloudFront Function: reescritura de subdirectorios ────
# Convierte /blog/ → /blog/index.html antes de que llegue a S3.
# Sin esto, S3 devuelve 403 para rutas de subdirectorio y CloudFront
# sirve el index.html raíz, rompiendo las rutas relativas del CSS.
resource "aws_cloudfront_function" "rewrite_index" {
  name    = "rewrite-index-html"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Si termina en '/', añade index.html
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      }
      // Si no tiene extensión de fichero, añade /index.html
      else if (!uri.split('/').pop().includes('.')) {
        request.uri += '/index.html';
      }

      return request;
    }
  EOT
}

# ── Data sources: políticas gestionadas por AWS ───────────
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# EDITAR: Descomenta si quieres headers de seguridad automáticos (HSTS, X-Frame, etc.)
# data "aws_cloudfront_response_headers_policy" "security_headers" {
#   name = "Managed-SecurityHeadersPolicy"
# }
