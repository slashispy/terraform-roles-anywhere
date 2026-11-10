#!/usr/bin/env bash
# Genera una CA y un certificado cliente SOLO PARA LABORATORIO.
# En producción usa AWS Private CA o tu PKI corporativa (vida corta + renovación automática).
set -euo pipefail

OUT_DIR="${1:-$(dirname "$0")/../pki}"
CLIENT_CN="${2:-onprem-backup-01}"

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"
umask 077

# --- CA ---
cat > ca.cnf <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3_ca
prompt = no
[dn]
CN = Lab Roles Anywhere CA
[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
EOF

openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -x509 -new -key ca.key -sha256 -days 365 -config ca.cnf -out ca.crt

# --- Certificado cliente (vida corta: 30 días) ---
cat > client.ext <<'EOF'
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = clientAuth
EOF

openssl ecparam -name prime256v1 -genkey -noout -out client.key
openssl req -new -key client.key -subj "/CN=${CLIENT_CN}" -out client.csr
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -sha256 -days 30 -extfile client.ext -out client.crt

rm -f client.csr ca.cnf client.ext ca.srl
chmod 600 ./*.key

echo "PKI de laboratorio generada en: $(pwd)"
echo "  CA (pública):      ca.crt   -> úsala en terraform (ca_certificate_pem_path)"
echo "  Cert del workload: client.crt / client.key (CN=${CLIENT_CN})"
echo "NUNCA subas *.key a git."
