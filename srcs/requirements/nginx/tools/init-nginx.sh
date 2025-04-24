#!/bin/bash
set -e

# Debug output
echo "Initializing Nginx with domain: ${DOMAIN_NAME}"

# Process the template and output to the correct location
envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ]; then
    echo "Generating SSL certificate for ${DOMAIN_NAME:-localhost}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=XX/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME:-localhost}"
fi

# Make sure the certificate has proper permissions
chmod 644 /etc/nginx/ssl/nginx.crt
chmod 600 /etc/nginx/ssl/nginx.key

# Check the Nginx configuration
echo "Checking Nginx configuration..."
nginx -t

# Execute the command passed to docker
echo "Starting Nginx..."
exec "$@"