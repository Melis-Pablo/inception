#!/bin/bash
set -e

# Replace environment variables in the Nginx conf
envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating SSL certificate for ${DOMAIN_NAME:-localhost}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=XX/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME:-localhost}"
fi

# Execute the command passed to docker
exec "$@"