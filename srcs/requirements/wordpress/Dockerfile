# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive 

# Update and install PHP, PHP-FPM, and required PHP extensions for WordPress
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    wget \
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Create directory for PHP-FPM to store its PID file and socket
RUN mkdir -p /run/php && \
    chmod 755 /run/php

# Install WP-CLI for WordPress management
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Download and extract WordPress
RUN mkdir -p /var/www/html && \
    wget https://wordpress.org/wordpress-6.4.3.tar.gz && \
    tar -xzf wordpress-6.4.3.tar.gz -C /var/www/html && \
    rm wordpress-6.4.3.tar.gz && \
    chown -R www-data:www-data /var/www/html

# Copy WordPress configuration file
COPY ./conf/wp-config.php /var/www/html/wordpress/

# Copy initialization script
COPY ./tools/init-wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-wordpress.sh

# Set working directory
WORKDIR /var/www/html/wordpress

# Expose the PHP-FPM port
EXPOSE 9000

# Run the initialization script, then start PHP-FPM in foreground mode
ENTRYPOINT ["init-wordpress.sh"]
CMD ["php-fpm7.4", "-F"]