# ============================================================
# ROUTE53 — Alias records apuntando a CloudFront
#
# Un Alias record es el equivalente AWS a un CNAME en el apex
# (@). A diferencia de un CNAME normal, un Alias puede usarse
# en el dominio raíz (andresexplica.com) y no tiene coste
# adicional de query.
#
# IMPORTANTE: allow_overwrite = true sobrescribe los registros
# A que ya existían en la hosted zone apuntando al servidor
# anterior. Sin esto, Terraform fallaría con un conflicto.
# ============================================================

# ── Registro A para el dominio raíz (apex) ────────────────
# andresexplica.com → CloudFront
resource "aws_route53_record" "apex" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = var.domain_name   # andresexplica.com
  type            = "A"
  allow_overwrite = true              # Sobrescribe el A record anterior

  # Un Alias record no tiene TTL; lo gestiona AWS internamente
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    # Z2FDTNDATAQYW2 es el hosted_zone_id fijo de TODOS los CloudFront
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── Registro A para www ────────────────────────────────────
# www.andresexplica.com → CloudFront
resource "aws_route53_record" "www" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "www.${var.domain_name}"  # www.andresexplica.com
  type            = "A"
  allow_overwrite = true                       # Sobrescribe el A record anterior

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── Registro AAAA (IPv6) para el apex ─────────────────────
# CloudFront tiene is_ipv6_enabled = true, así que añadimos
# también los registros AAAA para que funcione con IPv6.
resource "aws_route53_record" "apex_ipv6" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = var.domain_name
  type            = "AAAA"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── Registro AAAA (IPv6) para www ─────────────────────────
resource "aws_route53_record" "www_ipv6" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "www.${var.domain_name}"
  type            = "AAAA"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
