# Certificate Generation Scripts

This directory contains scripts to generate a complete Certificate Authority (CA) and certificates for mTLS authentication.

## Prerequisites

- OpenSSL installed on your system
- Bash shell

## Scripts Overview

### 1. Generate CA Certificate
**Script:** `1_gen_ca.sh`

Generates a self-signed Certificate Authority (CA) that will be used to sign server and client certificates.

```bash
./1_gen_ca.sh
```

**Output:**
- `ca/ca.key` - CA private key
- `ca/ca.crt` - CA certificate (valid for 365 days)

---

### 2. Generate Server Certificate
**Script:** `2_gen_server_cert.sh`

Creates a server certificate signed by the CA. The server certificate is configured for `localhost` by default.

```bash
./2_gen_server_cert.sh
```

**Requirements:** Must run `1_gen_ca.sh` first.

**Output:**
- `server/server.key` - Server private key (2048-bit RSA)
- `server/server.csr` - Certificate Signing Request
- `server/server.crt` - Signed server certificate (valid for 365 days)

---

### 3. Generate Client Certificate
**Script:** `3_gen_client_cert.sh`

Creates a client certificate and PKCS12 bundle (.p12) for mTLS authentication. The client key is encrypted with AES-256.

```bash
./3_gen_client_cert.sh <client_name>
```

**Arguments:**
- `<client_name>` - A unique identifier for the client (e.g., `john-doe`, `app1`, etc.)

**Example:**
```bash
./3_gen_client_cert.sh client
```

**Requirements:** Must run `1_gen_ca.sh` first.

**Output:**
- `client/<client_name>.key` - Encrypted client private key (2048-bit RSA with AES-256)
- `client/<client_name>.csr` - Certificate Signing Request
- `client/<client_name>.crt` - Signed client certificate (valid for 1095 days / 3 years)
- `client/<client_name>.p12` - PKCS12 bundle containing the client certificate, key, and CA certificate

**Note:** You will be prompted to:
1. Enter a passphrase for the private key encryption
2. Enter an export password for the .p12 file (this password is used when loading the .p12 file in applications)

---

## Quick Start

Run all scripts in order to generate a complete mTLS setup:

```bash
# 1. Generate CA
./1_gen_ca.sh

# 2. Generate server certificate
./2_gen_server_cert.sh

# 3. Generate client certificate
./3_gen_client_cert.sh client
```

## Directory Structure

After running all scripts, the directory structure will be:

```
certs/
├── ca/
│   ├── ca.key          # CA private key
│   ├── ca.crt          # CA certificate
│   └── ca.srl          # Serial number file
├── server/
│   ├── server.key      # Server private key
│   ├── server.csr      # Server CSR
│   └── server.crt      # Server certificate
└── client/
    ├── <name>.key      # Client private key (encrypted)
    ├── <name>.csr      # Client CSR
    ├── <name>.crt      # Client certificate
    └── <name>.p12      # PKCS12 bundle for mTLS
```

## Using the Certificates

### For NGINX (Server-side)
- Use `server/server.crt` and `server/server.key` for SSL configuration
- Use `ca/ca.crt` to verify client certificates

### For Python/curl (Client-side)
- Use `client/<name>.p12` with the export password you set
- See the `../examples/` directory for usage examples

## Security Notes

⚠️ **Important:**
- Keep all `.key` files secure and never commit them to version control
- The `.p12` files contain both the certificate and private key
- Store passwords securely
- Consider adding `*.key` and `*.p12` to `.gitignore`
