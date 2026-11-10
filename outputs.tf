output "trust_anchor_arn" {
  value = aws_rolesanywhere_trust_anchor.this.arn
}

output "profile_arn" {
  value = aws_rolesanywhere_profile.this.arn
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

# Variables listas para usar con scripts/run_outside_aws.sh
output "env_for_scripts" {
  value = <<-EOT
    export RA_TRUST_ANCHOR_ARN=${aws_rolesanywhere_trust_anchor.this.arn}
    export RA_PROFILE_ARN=${aws_rolesanywhere_profile.this.arn}
    export RA_ROLE_ARN=${aws_iam_role.this.arn}
    export AWS_REGION=${var.region}
  EOT
}
