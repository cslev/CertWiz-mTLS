# CertWiz-mTLS
A lightweight, end-to-end toolkit for implementing Mutual TLS (mTLS), automate processes, and provide examples and templates for NGINX reverse proxies, python-based clients, and more

## Getting Started

### Clone the Repository
```bash
git clone https://github.com/yourusername/CertWiz-mTLS.git
cd CertWiz-mTLS
```

### Set Up Python Environment
```bash
# Create a virtual environment
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate  # On Linux/macOS
# or
.venv\Scripts\activate     # On Windows

# Install required packages
pip install -r requirements.txt
```

## Certificate Generation

To generate certificates for mTLS, use the scripts in the `certs/` directory:

```bash
cd certs

# 1. Generate Certificate Authority (CA)
./1_gen_ca.sh

# 2. Generate server certificate
./2_gen_server_cert.sh

# 3. Generate client certificate (replace 'client' with your desired name)
./3_gen_client_cert.sh client
```

For detailed instructions and options, see [certs/README.md](certs/README.md). 
