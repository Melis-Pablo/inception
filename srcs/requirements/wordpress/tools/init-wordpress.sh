#!/bin/bash
set -e

echo "Starting WordPress initialization..."
echo "===== Environment Variables ====="
echo "MYSQL_DATABASE: ${MYSQL_DATABASE}"
echo "MYSQL_USER: ${MYSQL_USER}"
echo "DOMAIN_NAME: ${DOMAIN_NAME}"
echo "WP_TITLE: ${WP_TITLE}"
echo "WP_URL: ${WP_URL}"

# Create a debug file to verify environment variables
echo "Creating debug file for environment variables..."
env > /var/www/html/env_debug.txt

# Ensure environment variables are passed to PHP
echo "Updating PHP-FPM configuration to pass environment variables..."
grep -q "env\[MYSQL_DATABASE\]" /etc/php/7.4/fpm/pool.d/www.conf || {
    echo "env[MYSQL_DATABASE] = \$MYSQL_DATABASE" >> /etc/php/7.4/fpm/pool.d/www.conf
    echo "env[MYSQL_USER] = \$MYSQL_USER" >> /etc/php/7.4/fpm/pool.d/www.conf
    echo "env[DOMAIN_NAME] = \$DOMAIN_NAME" >> /etc/php/7.4/fpm/pool.d/www.conf
    echo "env[WP_TITLE] = \$WP_TITLE" >> /etc/php/7.4/fpm/pool.d/www.conf
    echo "env[WP_URL] = \$WP_URL" >> /etc/php/7.4/fpm/pool.d/www.conf
    echo "clear_env = no" >> /etc/php/7.4/fpm/pool.d/www.conf
}

# Get DB password from secrets
DB_PASSWORD=$(cat /run/secrets/db_password)

# Try to connect to the database with proper error handling
for i in {1..30}; do
    echo "Attempt $i/30: Trying to connect to MariaDB..."
    
    if mysql -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>/dev/null; then
        echo "Successfully connected to MariaDB database!"
        CONNECTION_SUCCESSFUL=true
        break
    fi
    
    echo "Connection failed. MySQL error:"
    mysql -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>&1 || true
    
    if [ $i -eq 30 ]; then
        echo "ERROR: Could not connect to MariaDB after 30 attempts"
        echo "Detailed connection attempt:"
        mysql -v -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "USE ${MYSQL_DATABASE};" || true
        echo "Trying fallback direct connection test..."
        nc -zv mariadb 3306 || true
        exit 1
    fi
    
    sleep 5
done

# Set proper permissions
echo "Setting proper permissions for WordPress files"
chown -R www-data:www-data /var/www/html/wordpress

# Check if WordPress config is properly set up
if ! grep -q "DB_PASSWORD.*run/secrets/db_password" /var/www/html/wordpress/wp-config.php; then
    echo "Updating wp-config.php with proper configuration..."
    
    # Generate random keys
    WP_SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    # Replace default salts with random ones
    sed -i "/AUTH_KEY/,/NONCE_SALT/c\\
define('AUTH_KEY',         '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('SECURE_AUTH_KEY',  '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('LOGGED_IN_KEY',    '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('NONCE_KEY',        '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('AUTH_SALT',        '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('SECURE_AUTH_SALT', '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('LOGGED_IN_SALT',   '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
define('NONCE_SALT',       '$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)');\\
" /var/www/html/wordpress/wp-config.php
    
    echo "WordPress configuration updated with new salt keys"
fi

# Check if WordPress is already installed
echo "Checking if WordPress is already installed..."
if ! wp core is-installed --path="/var/www/html/wordpress" --allow-root 2>/dev/null; then
    echo "WordPress not installed. Installing..."
    
    # Get admin credentials from secrets
    WP_ADMIN_USER=$(grep -oP 'WP_ADMIN_USER=\K[^\n]+' /run/secrets/credentials || echo "manager")
    WP_ADMIN_PASSWORD=$(grep -oP 'WP_ADMIN_PASSWORD=\K[^\n]+' /run/secrets/credentials || echo "manager_password")
    WP_ADMIN_EMAIL=$(grep -oP 'WP_ADMIN_EMAIL=\K[^\n]+' /run/secrets/credentials || echo "admin@example.com")
    
    # Get regular user credentials from secrets
    WP_REGULAR_USER=$(grep -oP 'WP_REGULAR_USER=\K[^\n]+' /run/secrets/credentials || echo "user1")
    WP_REGULAR_PASSWORD=$(grep -oP 'WP_REGULAR_PASSWORD=\K[^\n]+' /run/secrets/credentials || echo "user1_password")
    WP_REGULAR_EMAIL=$(grep -oP 'WP_REGULAR_EMAIL=\K[^\n]+' /run/secrets/credentials || echo "user1@example.com")
    
    echo "Admin user: $WP_ADMIN_USER"
    echo "Regular user: $WP_REGULAR_USER"
    
    # Create wp-config.php directly with wp-cli if it doesn't exist
    if [ ! -f "/var/www/html/wordpress/wp-config.php" ]; then
        echo "Creating wp-config.php with wp-cli..."
        wp config create \
            --path="/var/www/html/wordpress" \
            --dbname="${MYSQL_DATABASE}" \
            --dbuser="${MYSQL_USER}" \
            --dbpass="${DB_PASSWORD}" \
            --dbhost="mariadb" \
            --allow-root
    fi
    
    # Install WordPress
    echo "Installing WordPress core..."
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
    echo "Creating regular user..."
    wp user create "${WP_REGULAR_USER}" "${WP_REGULAR_EMAIL}" \
        --role=author \
        --user_pass="${WP_REGULAR_PASSWORD}" \
        --path="/var/www/html/wordpress" \
        --allow-root
    
    # Update plugins
    echo "Updating WordPress plugins..."
    wp plugin update --all --path="/var/www/html/wordpress" --allow-root
    
    echo "WordPress installation completed!"
else
    echo "WordPress is already installed!"
fi

# Final permission setup
echo "Setting final permissions for WordPress files"
chown -R www-data:www-data /var/www/html/wordpress

# Create a PHP info file to test environment variables
cat > /var/www/html/wordpress/phpinfo.php << 'EOF'
<?php
phpinfo();
EOF

# Test PHP environment variables directly
echo "Testing PHP environment variable access..."
php -r "echo 'MYSQL_DATABASE via PHP: ' . getenv('MYSQL_DATABASE') . \"\n\";"
php -r "echo 'MYSQL_USER via PHP: ' . getenv('MYSQL_USER') . \"\n\";"

echo "Starting PHP-FPM with command: $@"
# Start PHP-FPM
exec "$@"