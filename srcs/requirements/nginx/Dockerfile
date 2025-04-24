# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Update and install nginx and openssl for certificate generation
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/www/html \
    && mkdir -p /etc/nginx/ssl \
    && mkdir -p /etc/nginx/templates

# Copy template instead of final config
COPY ./conf/default.conf.template /etc/nginx/templates/default.conf.template

# Copy NGINX configuration
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

# Copy initialization script
COPY ./tools/init-nginx.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-nginx.sh

# Expose HTTPS port
EXPOSE 443

# Start NGINX in foreground mode
ENTRYPOINT [ "/usr/local/bin/init-nginx.sh" ]
CMD ["nginx", "-g", "daemon off;"]