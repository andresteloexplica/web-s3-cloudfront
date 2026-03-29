# S3 + CloudFront con Terraform

Infraestructura como código para desplegar una web estática en AWS con S3 + CloudFront, HTTPS automático vía ACM y dominio propio. Coste real: menos de 0,50 € al mes para una landing con 10.000 visitas.

> Infrastructure as Code no es solo automatización. Es documentación ejecutable que nunca queda desactualizada.

---

## ¿Qué despliega este código?

- Bucket S3 **privado** para los archivos de la web
- Distribución CloudFront con **OAC** (Origin Access Control)
- Bucket policy que permite a CloudFront leer S3
- Redirección automática de HTTP a HTTPS
- Soporte para **dominio propio** y certificado ACM (opcional)

---

## Cuándo usar esto (y cuándo no)

✅ **Sirve para:** landings, portfolios, webs HTML/CSS/JS, blogs estáticos, Next.js en modo `next export`

❌ **No sirve para:** WordPress, tiendas con carrito, apps con autenticación en servidor, Next.js con SSR

La regla: si al abrir el inspector de red todo son `.html`, `.css`, `.js` y assets estáticos, es candidato para este stack.

---

## Estructura de archivos

```
├── acm.tf                   # Certificado SSL + validación DNS automática en Route53
├── cloudfront.tf            # Distribución CloudFront + OAC
├── outputs.tf               # Outputs: URL de CloudFront, ID de distribución, bucket name
├── provider.tf              # Dos providers: región principal + us-east-1 para ACM
├── route53.tf               # Registros DNS
├── s3.tf                    # Bucket S3 privado + política + cifrado + versionado
├── variables.tf             # Variables configurables
└── terraform.tfvars.example # Plantilla de valores — copia y edita
```

---

## Requisitos previos

- [Terraform](https://terraform.io) ≥ 1.5
- AWS CLI configurado con permisos de S3, CloudFront, IAM y ACM

```bash
terraform -version
aws sts get-caller-identity
```

---

## Uso

### 1 — Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
bucket_name  = "mi-web-com"      # Nombre único global para el bucket S3
aws_region   = "eu-west-1"       # Región donde crear el bucket
environment  = "production"

# Opcional: dominio propio
# domain_name         = "www.midominio.com"
# acm_certificate_arn = "arn:aws:acm:us-east-1:..."
```

### 2 — Inicializar

```bash
terraform init
```

### 3 — Revisar el plan

```bash
terraform plan
```

### 4 — Aplicar

```bash
terraform apply
```

El bucket S3 tarda segundos. La distribución CloudFront tarda entre 5 y 15 minutos en propagarse. Al terminar verás:

```
Outputs:

cloudfront_domain          = "d3abc123xyz.cloudfront.net"
cloudfront_distribution_id = "E3XXXXXXXXXX"
s3_bucket_name             = "mi-web-com"
```

### 5 — Subir los archivos

```bash
# Subir archivos al bucket
aws s3 sync ./dist s3://TU_BUCKET_NAME --delete

# Invalidar caché de CloudFront
aws cloudfront create-invalidation \
  --distribution-id TU_DISTRIBUTION_ID \
  --paths "/*"
```

Las primeras 1.000 invalidaciones al mes son gratuitas.

---

## Dominio propio con HTTPS

El certificado ACM **debe estar en `us-east-1`** — requisito de CloudFront independientemente de la región del resto de la infraestructura.

1. Crea el certificado en ACM (`us-east-1`) y valídalo por DNS
2. Copia el ARN del certificado a `terraform.tfvars`
3. Descomenta `domain_name` y `acm_certificate_arn`
4. Ejecuta `terraform apply`
5. Crea un registro CNAME (o ALIAS en Route 53) apuntando tu dominio al `cloudfront_domain` de los outputs

---

## Destruir la infraestructura

```bash
# Primero vacía el bucket (Terraform no puede borrar buckets con contenido)
aws s3 rm s3://TU_BUCKET_NAME --recursive

# Luego destruye
terraform destroy
```

---

## Comparativa de costes

```
                     Hosting tradicional    S3 + CloudFront
─────────────────────────────────────────────────────────────
Coste mensual        15-20 €                < 0,50 €
HTTPS                Manual / cPanel        Automático (ACM)
CDN global           Extra o no incluida    Incluida (400+ PoP)
Escalabilidad        Limitada por plan      Ilimitada
Mantenimiento        Actualizaciones, SSH   Ninguno
Uptime SLA           Variable               99,9 %+ (AWS)
```

---

## Seguridad

| Control | Implementación |
|---|---|
| Bucket privado | `public_access_block` con los 4 flags en `true` |
| Acceso origen firmado | OAC con `signing_behavior = "always"` y SigV4 |
| Least privilege | Política del bucket: solo `s3:GetObject` desde esta distribución |
| HTTPS obligatorio | `viewer_protocol_policy = "redirect-to-https"` |
| TLS 1.2 mínimo | `minimum_protocol_version = "TLSv1.2_2021"` |
| Cifrado en reposo | SSE-S3 (AES-256) con Bucket Key activado |

---

## Autor

**Andrés De la Roche** — Cloud Architect & Sys Admin  
[andresexplica.com](https://www.andresexplica.com) · [LinkedIn](https://www.linkedin.com/in/andr%C3%A9s-felipe-de-la-roche-19383924/)

Post completo con explicación detallada: [S3 + CloudFront: de cero a Terraform](https://www.andresexplica.com/blog/terraform-cloudfront-s3.html)
