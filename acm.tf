# ============================================================
# ACM — Certificado SSL para andresexplica.com
#
# IMPORTANTE: debe crearse en us-east-1 (requisito de CloudFront).
# La validación es automática vía DNS usando Route53.
# ============================================================

# ── Busca la hosted zone de Route53 por nombre de dominio ─
# No hardcodeamos el ID; Terraform lo resuelve solo.
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
  # No necesita provider especial: Route53 es global
}

# ── Solicita el certificado en us-east-1 ──────────────────
resource "aws_acm_certificate" "website" {
  provider = aws.us_east_1 # ← obligatorio para CloudFront

  domain_name               = var.domain_name               # andresexplica.com
  subject_alternative_names = ["www.${var.domain_name}"]    # www.andresexplica.com
  validation_method         = "DNS"                         # automático con Route53

  # Permite recrear el cert sin downtime si se modifica el dominio
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Web+acm"
  }
}

# ── Crea los registros CNAME en Route53 para validar el cert ─
# ACM genera un registro CNAME único por dominio; Terraform los añade.
# for_each porque el cert cubre dos nombres (apex + www).
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true # seguro: ACM reutiliza el mismo CNAME si ya existe
}

# ── Espera a que ACM confirme la validación ───────────────
# Este recurso "bloquea" hasta que el certificado está en estado ISSUED.
# CloudFront depende de este recurso, no del certificado directamente,
# así que Terraform no intentará crear la distribución hasta que el
# certificado esté 100% validado.
resource "aws_acm_certificate_validation" "website" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
