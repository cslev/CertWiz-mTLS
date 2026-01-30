# Certificate Management Scripts

This directory contains a suite of Bash scripts for managing a private Certificate Authority (CA) using OpenSSL. The scripts are designed to support **Profiles**, allowing you to manage multiple distinct CAs (e.g., `prod`, `dev`, `iot-network`) within the same repository without file collisions.

## Structure

When you run the scripts with a profile name (e.g., `-p my-project`), a subdirectory is created:

```
certs/
├── my-project/          # Profile Directory
│   ├── ca/              # CA private key and cert
│   ├── db/              # OpenSSL database (index.txt, serial)
│   ├── server/          # Generated server keys/certs
│   ├── client/          # Generated client keys/certs
│   └── openssl.cnf      # Profile-specific config
├── 1_gen_ca.sh
├── 2_gen_server_cert.sh
├── ...
```

## Usage

All scripts accept a `-p <name>` flag. If omitted, the profile defaults to `default`.

### 1. Initialize a CA
Creates the directory structure and the root CA certificate.
```bash
./1_gen_ca.sh -p my-project
```

### 2. Generate a Server Certificate
Generates a key and certificate for a server (e.g., NGINX), signed by the profile's CA.
In fact, if you have your own public, non-self-signed cert, you can skip this step. 
The rest for mTLS are required though.
```bash
./2_gen_server_cert.sh -p my-project -n myserver.local
```

### 3. Generate a Client Certificate
Generates a key and certificate for a client (mTLS), signed by the profile's CA. Output includes `.key`, `.crt`, and `.p12` (PFX) bundles.
```bash
./3_gen_client_cert.sh -p my-project -n client01
```

### 4. Revoke a Client Certificate
Revokes a certificate by name and updates the Certificate Revocation List (CRL).
```bash
./4_revoke_client.sh -p my-project -n client01
```
The CRL file will be at `certs/my-project/ca/ca.crl`.
You can verify the revocation status in `certs/my-project/db/index.txt` (look for the 'R' flag).

### 5. Cleanup
Removes certificates and keys for a specific profile (or all of them).
```bash
# Clean specific profile
./clean.sh -p my-project

# Clean ALL profiles
./clean.sh -a
```
