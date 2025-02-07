# Alpine for lighter Base OS (penultimate stable verison)
FROM alpine:3.20

# Install NGINX and OpenSSL
RUN apk update && apk add --no-cache \
    nginx \
    openssl \
    && mkdir -p /run/nginx

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy setup script
COPY tools/setup-nx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-nx.sh

# Create necessary directories
RUN mkdir -p /var/www/html \
    && mkdir -p /etc/nginx/ssl

# Expose HTTPS port
EXPOSE 443

# Use setup script as entrypoint
ENTRYPOINT ["/usr/local/bin/setup-nx.sh"]