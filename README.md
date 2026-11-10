# AWS IAM Roles Anywhere: acceso a AWS sin Access Keys

Terraform para que un workload fuera de AWS (on-prem, VM, otro cloud) use S3 con
credenciales temporales de STS, autenticándose con un certificado X.509 en vez de claves estáticas.

El script que consume esto desde fuera de AWS vive en el utility belt:
`~/Developer/go/proyectos/kind-gitops-utility-belt/scripts/06-aws-roles-anywhere.sh`

## Arquitectura

Diagrama completo del flujo de autenticación (6 pasos, desde el certificado hasta S3):
[`kind-gitops-utility-belt/docs/aws-roles-anywhere.md`](https://github.com/slashispy/kind-gitops-utility-belt/blob/main/docs/aws-roles-anywhere.md)

```
 workload ──(1) CreateSession firmada con client.key + cert──▶ Roles Anywhere
                                                                   │ (2) valida cert contra Trust Anchor (CA) + CRL
                                                                   │ (3) valida trust policy (SourceArn + CN)
                                                                   ▼
 workload ◀──(5) credenciales temporales (1 h)────────────────── STS AssumeRole (4)
    │
    └─(6) PutObject ──▶ S3   (rol ∩ session policy: solo bucket/backups/*)   ──▶ CloudTrail
```

## Controles de seguridad aplicados

- Sin credenciales estáticas: sesiones de 1 hora, renovadas automáticamente.
- Trust policy restringida a `rolesanywhere.amazonaws.com`, a un trust anchor concreto (`aws:SourceArn`) y a CNs de certificado permitidos (`x509Subject/CN`).
- Mínimo privilegio: solo `PutObject` bajo un prefijo y `ListBucket` con condición `s3:prefix`.
- Session policy en el Profile como tope adicional de permisos.
- Certificados de vida corta (30 días en el lab).
- Auditoría en CloudTrail (eventos `CreateSession` de Roles Anywhere).

## Uso

```bash
# 1. PKI de laboratorio (en prod: AWS Private CA o PKI corporativa)
./scripts/gen_lab_pki.sh            # genera ./pki/{ca,client}.{crt,key}

# 2. Infraestructura
cp terraform.tfvars.example terraform.tfvars   # editar bucket y CNs
terraform init && terraform apply

# 3. Desde el workload externo (utility belt)
cd ~/Developer/go/proyectos/kind-gitops-utility-belt
./scripts/06-aws-roles-anywhere.sh sts get-caller-identity   # verifica el rol asumido
./scripts/06-aws-roles-anywhere.sh s3 cp ./backup.tar.gz s3://mi-bucket-de-backups/backups/
```

## Producción: pendientes recomendados

- Emitir certificados con AWS Private CA / Vault PKI / cert-manager, con renovación automática.
- Publicar CRL en Roles Anywhere para revocar certificados comprometidos.
- Alarma en CloudWatch/EventBridge ante `CreateSession` desde CNs inesperados o IPs fuera de rango.
- Estado remoto de Terraform (S3 + lock) y escaneo con Checkov/tfsec en el pipeline.
- Cifrar el bucket con KMS y habilitar S3 Block Public Access.
