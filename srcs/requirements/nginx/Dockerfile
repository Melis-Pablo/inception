# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Update and install nginx and openssl for certificate generation
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html \
    && mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=XX/ST=State/L=City/O=Organization/CN=pmelis.42.fr"

# Copy NGINX configuration
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf

# Expose HTTPS port
EXPOSE 443

# Start NGINX in foreground mode
CMD ["nginx", "-g", "daemon off;"]