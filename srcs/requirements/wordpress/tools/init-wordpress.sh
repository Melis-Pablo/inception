#!/bin/bash
set -e

# Get passwords from secrets
DB_PASSWORD=$(cat /run/secrets/db_password)

# Wait for database connection
echo "Waiting for database connection..."
for i in {1..30}; do
    if mysql -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>/dev/null; then
        echo "Database connection established"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "Could not connect to MariaDB after 30 attempts"
        exit 1
    fi
    
    sleep 5
done

# Set proper permissions
chown -R www-data:www-data /var/www/html/wordpress

# Check if WordPress is already installed
if ! wp core is-installed --path="/var/www/html/wordpress" --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    
    # Get credentials from secrets
    WP_ADMIN_USER=$(grep -oP 'WP_ADMIN_USER=\K[^\n]+' /run/secrets/credentials)
    WP_ADMIN_PASSWORD=$(grep -oP 'WP_ADMIN_PASSWORD=\K[^\n]+' /run/secrets/credentials)
    WP_ADMIN_EMAIL=$(grep -oP 'WP_ADMIN_EMAIL=\K[^\n]+' /run/secrets/credentials)
    WP_REGULAR_USER=$(grep -oP 'WP_REGULAR_USER=\K[^\n]+' /run/secrets/credentials)
    WP_REGULAR_PASSWORD=$(grep -oP 'WP_REGULAR_PASSWORD=\K[^\n]+' /run/secrets/credentials)
    WP_REGULAR_EMAIL=$(grep -oP 'WP_REGULAR_EMAIL=\K[^\n]+' /run/secrets/credentials)
    
    # Fix for salt generation - use individual keys instead of API
    sed -i "s/define('AUTH_KEY',         'placeholder');/define('AUTH_KEY',         '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('SECURE_AUTH_KEY',  'placeholder');/define('SECURE_AUTH_KEY',  '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('LOGGED_IN_KEY',    'placeholder');/define('LOGGED_IN_KEY',    '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('NONCE_KEY',        'placeholder');/define('NONCE_KEY',        '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('AUTH_SALT',        'placeholder');/define('AUTH_SALT',        '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('SECURE_AUTH_SALT', 'placeholder');/define('SECURE_AUTH_SALT', '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('LOGGED_IN_SALT',   'placeholder');/define('LOGGED_IN_SALT',   '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    sed -i "s/define('NONCE_SALT',       'placeholder');/define('NONCE_SALT',       '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');/" /var/www/html/wordpress/wp-config.php
    
    # Install WordPress
    wp core install \
        --path="/var/www/html/wordpress" \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    # Create regular user
    wp user create "${WP_REGULAR_USER}" "${WP_REGULAR_EMAIL}" \
        --role=author \
        --user_pass="${WP_REGULAR_PASSWORD}" \
        --path="/var/www/html/wordpress" \
        --allow-root
    
    echo "WordPress installation completed"
else
    echo "WordPress is already installed"
fi

# Final permission setup
chown -R www-data:www-data /var/www/html/wordpress

# Start PHP-FPM
exec "$@"