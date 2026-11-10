variable "region" {
  description = "Región de AWS."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefijo para nombrar los recursos."
  type        = string
  default     = "onprem-backup"
}

variable "ca_certificate_pem_path" {
  description = "Ruta al certificado PEM de la CA (solo la parte pública) que firma los certificados de los workloads."
  type        = string
}

variable "allowed_cert_cns" {
  description = "Lista de Common Names de certificados autorizados a asumir el rol."
  type        = list(string)
}

variable "bucket_name" {
  description = "Bucket S3 al que el workload externo tendrá acceso (debe existir)."
  type        = string
}

variable "bucket_prefix" {
  description = "Prefijo dentro del bucket donde se puede escribir."
  type        = string
  default     = "backups/"
}

variable "session_duration_seconds" {
  description = "Duración de las credenciales temporales (900 a 3600 en Roles Anywhere por defecto)."
  type        = number
  default     = 3600
}
