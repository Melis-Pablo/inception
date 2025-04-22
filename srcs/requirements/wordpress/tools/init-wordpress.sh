#!/bin/bash
set -e

echo "Starting WordPress initialization..."
echo "MYSQL_DATABASE: ${MYSQL_DATABASE}"
echo "MYSQL_USER: ${MYSQL_USER}"
echo "DOMAIN_NAME: ${DOMAIN_NAME}"
echo "WP_TITLE: ${WP_TITLE}"
echo "WP_URL: ${WP_URL}"

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysql -h mariadb -u "${MYSQL_USER}" -p"$(cat /run/secrets/db_password)" -e "SHOW DATABASES;" &>/dev/null; then
        echo "MariaDB connection successful!"
        break
    fi
    echo "Attempt $i/30: MariaDB not ready yet. Waiting..."
    if [ $i -eq 30 ]; then
        echo "ERROR: Could not connect to MariaDB after 30 attempts"
        echo "Last error:"
        mysql -h mariadb -u "${MYSQL_USER}" -p"$(cat /run/secrets/db_password)" -e "SHOW DATABASES;" || true
        exit 1
    fi
    sleep 5
done

# Set proper permissions
echo "Setting proper permissions for WordPress files"
chown -R www-data:www-data /var/www/html/wordpress

# Check if WordPress config is already adjusted
if ! grep -q "define.*DB_PASSWORD.*\/run\/secrets\/db_password" /var/www/html/wordpress/wp-config.php; then
    echo "Updating wp-config.php with proper configuration..."
    WP_SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "s/put your unique phrase here/$(echo $WP_SALT | sed -e 's/[\/&]/\\&/g')/g" /var/www/html/wordpress/wp-config.php
    sed -i "s/database_name_here/${MYSQL_DATABASE}/g" /var/www/html/wordpress/wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/g" /var/www/html/wordpress/wp-config.php
    echo "WordPress configuration updated"
fi

# Check if WordPress is already installed
echo "Checking if WordPress is already installed..."
if ! wp core is-installed --path="/var/www/html/wordpress" --allow-root 2>/dev/null; then
    echo "WordPress not installed. Installing..."
    
    # Get admin credentials from secrets
    WP_ADMIN_USER=$(grep -oP 'WP_ADMIN_USER=\K[^\n]+' /run/secrets/credentials)
    WP_ADMIN_PASSWORD=$(grep -oP 'WP_ADMIN_PASSWORD=\K[^\n]+' /run/secrets/credentials)
    WP_ADMIN_EMAIL=$(grep -oP 'WP_ADMIN_EMAIL=\K[^\n]+' /run/secrets/credentials)
    
    # Get regular user credentials from secrets
    WP_REGULAR_USER=$(grep -oP 'WP_REGULAR_USER=\K[^\n]+' /run/secrets/credentials)
    WP_REGULAR_PASSWORD=$(grep -oP 'WP_REGULAR_PASSWORD=\K[^\n]+' /run/secrets/credentials)
    WP_REGULAR_EMAIL=$(grep -oP 'WP_REGULAR_EMAIL=\K[^\n]+' /run/secrets/credentials)
    
    echo "Admin user: $WP_ADMIN_USER"
    echo "Regular user: $WP_REGULAR_USER"
    
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

echo "Starting PHP-FPM with command: $@"
# Start PHP-FPM
exec "$@"