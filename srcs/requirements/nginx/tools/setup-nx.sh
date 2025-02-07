#!/bin/sh

# Generate self-signed SSL certificate if not exists
if [ ! -f /etc/nginx/ssl/cert.pem ]; then
    # Create ssl directory
    mkdir -p /etc/nginx/ssl

    # Generate SSL certificate and key
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"
fi

# Start nginx in foreground (proper PID 1 handling)
exec nginx -g "daemon off;"