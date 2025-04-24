# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Update and install nginx, openssl, and gettext-base (for envsubst)
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/www/html \
    && mkdir -p /etc/nginx/ssl

# Copy NGINX configuration
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf.template

# Copy and make initialization script executable
COPY ./tools/init-nginx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-nginx.sh

# Expose HTTPS port
EXPOSE 443

# Start NGINX with initialization script
ENTRYPOINT ["/usr/local/bin/init-nginx.sh"]
CMD ["nginx", "-g", "daemon off;"]