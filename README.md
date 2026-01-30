# CertWiz-mTLS
CertWiz-mTLS is a comprehensive toolkit designed to simplify Mutual TLS (mTLS) implementation. It provides **automated bash scripts** for generating Certificate Authorities (CA), server certificates, and encrypted client keys with PKCS#12 bundles. 

The repository includes ready-to-use examples for integrating mTLS with **Python applications** (using `requests`), **CLI tools** (like `curl`), and **NGINX reverse proxies** (coming soon), making secure service-to-service communication accessible and easy to deploy.

<p align="center">
  <img src="assets/certwiz-mtls.png" alt="CertWiz-mTLS Logo" width="50%">
  <br>
  <em>image generate with Nano Banana</em>
</p>

## Getting Started

### Clone the Repository
```bash
git clone https://github.com/yourusername/CertWiz-mTLS.git
cd CertWiz-mTLS
```

### Python Environment & Examples

For instructions on setting up the Python environment and running the examples, please refer to [examples/python/README.md](examples/python/README.md).

## Certificate Generation

To generate certificates for mTLS, use the scripts in the `certs/` directory. All scripts require a `-p <profile>` argument to isolate different CAs.

```bash
cd certs

# 1. Generate Certificate Authority (CA)
./1_gen_ca.sh -p my-profile

# 2. Generate server certificate
./2_gen_server_cert.sh -p my-profile -n myserver

# 3. Generate client certificate
./3_gen_client_cert.sh -p my-profile -n client01

# 4. Revoke a client certificate
./4_revoke_client.sh -p my-profile -n client01
```

For detailed instructions and options, see [certs/README.md](certs/README.md). 
