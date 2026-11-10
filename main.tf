# Trust anchor: en quién confía AWS (tu CA / PKI corporativa).
resource "aws_rolesanywhere_trust_anchor" "this" {
  name    = "${var.name_prefix}-trust-anchor"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = file(var.ca_certificate_pem_path)
    }
  }
}

# Trust policy: solo Roles Anywhere, solo este trust anchor y solo CNs permitidos.
data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]

    principals {
      type        = "Service"
      identifiers = ["rolesanywhere.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_rolesanywhere_trust_anchor.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/CN"
      values   = var.allowed_cert_cns
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${var.name_prefix}-role"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.session_duration_seconds
}

# Mínimo privilegio: solo escribir/listar bajo un prefijo de un bucket.
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "WriteToPrefix"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["arn:aws:s3:::${var.bucket_name}/${var.bucket_prefix}*"]
  }

  statement {
    sid       = "ListPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.bucket_prefix}*"]
    }
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "${var.name_prefix}-s3-access"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# Profile: qué roles puede asumir y duración de la sesión.
resource "aws_rolesanywhere_profile" "this" {
  name             = "${var.name_prefix}-profile"
  enabled          = true
  role_arns        = [aws_iam_role.this.arn]
  duration_seconds = var.session_duration_seconds
  session_policy   = data.aws_iam_policy_document.s3_access.json # tope adicional de permisos
}
