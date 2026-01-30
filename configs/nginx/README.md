# NGINX mTLS Configurations

This directory contains modular NGINX configuration files designed to work together to provide a secure, mTLS-enabled reverse proxy.

## File Overview

### 1. `mtls_proxy.conf` (Example Server Block)
This is the main entry point example. It demonstrates how to:
-   Listen on port 443 (HTTPS).
-   Configure the SSL certificates (Server cert, CA cert for Verification, CRL).
-   Enforce mTLS (`ssl_verify_client on`).
-   Pass authentication headers to the backend.

### 2. `ssl.conf` (Security Hardening)
A shared snippet meant to be included in your `server` blocks.
-   Enforces TLS 1.2/1.3.
-   Sets strong Cipher Suites and Elliptic Curves (X25519).
-   Enables HSTS (HTTP Strict Transport Security).
-   Adds security headers (`X-Frame-Options`, `Content-Security-Policy`, etc.).

### 3. `proxy.conf` (Backend Headers)
A shared snippet to be included in your `location` blocks.
-   **Essentials**: Sets headers like `X-Forwarded-For`, `Host`, `Upgrade` (for WebSockets).
-   **mTLS Context**: Passes the client certificate details (`Subject`, `Issuer`, `Serial`, `Verification Status`) to the backend application as HTTP headers.
-   **Optional Tuning**: Contains commented-out sections for timeouts, buffers, and caching.

## Usage Guide

1.  **Generate Certificates** using the scripts in `../../certs/`.
2.  **Update Paths**: Text replace `/path/to/CertWiz-mTLS` in the `.conf` files with your actual absolute path.
3.  **Include in NGINX**:

   **Option A: Symlink (Recommended)**
   Link these files into your NGINX configuration directory.
   ```bash
   ln -s $(pwd)/configs/nginx/ssl.conf /etc/nginx/conf.d/ssl_certwiz.conf
   ln -s $(pwd)/configs/nginx/proxy.conf /etc/nginx/conf.d/proxy_certwiz.conf
   # Copy and edit the site config
   cp configs/nginx/mtls_proxy.conf /etc/nginx/sites-available/my-secure-app
   ```

   **Option B: Direct Include**
   In your `/etc/nginx/nginx.conf` or site config:
   ```nginx
   server {
       listen 443 ssl;
       
       # Security Settings
       include /path/to/CertWiz-mTLS/configs/nginx/ssl.conf;

       # ... certificate paths ...

       location / {
           # Proxy Settings (Headers & mTLS info)
           include /path/to/CertWiz-mTLS/configs/nginx/proxy.conf;
           proxy_pass http://localhost:8080;
       }
   }
   ```

4.  **Reload NGINX**: `sudo nginx -t && sudo nginx -s reload`
