# ============================================================
# OUTPUTS — Valores útiles tras el apply
# ============================================================

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront (necesario para invalidar caché)"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "URL de tu sitio en CloudFront (úsala en tu DNS si tienes dominio)"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront (para alias records en Route53)"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "deploy_command" {
  description = "Comando para subir los archivos del sitio al bucket S3"
  value       = "aws s3 sync ../ s3://${aws_s3_bucket.website.id} --exclude 'terraform/*' --exclude '.git/*' --delete"
}

output "invalidate_cache_command" {
  description = "Comando para invalidar la caché de CloudFront tras un deploy"
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
}
