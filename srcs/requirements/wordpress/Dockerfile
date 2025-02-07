# Alpine for lighter Base OS (penultimate stable verison)
FROM alpine:3.20

# Install required packages
RUN apk update && apk add --no-cache \
    php81 \
    php81-fpm \
    php81-mysqli \
    php81-json \
    php81-curl \
    php81-dom \
    php81-exif \
    php81-fileinfo \
    php81-mbstring \
    php81-openssl \
    php81-xml \
    php81-zip \
    php81-redis \
    wget \
    curl

# WordPress installation and directory setup
WORKDIR /var/www

# Install WordPress CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY ./conf/www.conf /etc/php81/php-fpm.d/www.conf

# Copy WordPress setup script
COPY ./tools/wp-setup.sh /wp-setup.sh
RUN chmod +x /wp-setup.sh

# Create wordpress directory and set permissions
RUN mkdir -p /var/www/wordpress && \
    chown -R nobody:nobody /var/www/wordpress

WORKDIR /var/www/wordpress

# Set PHP-FPM to run as nobody
RUN sed -i "s|user = nobody|user = nobody|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|group = nobody|group = nobody|g" /etc/php81/php-fpm.d/www.conf

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["/usr/sbin/php-fpm81", "-F"]