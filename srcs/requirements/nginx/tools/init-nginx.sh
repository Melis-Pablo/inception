#!/bin/bash
set -e

# Process the template and output to the correct location
envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ]; then
    echo "Generating SSL certificate for ${DOMAIN_NAME}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=XX/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
fi

exec "$@"