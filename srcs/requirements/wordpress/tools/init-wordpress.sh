#!/bin/bash
set -e

# Wait for MariaDB to be ready
until mysql -h mariadb -u "${MYSQL_USER}" -p"$(cat /run/secrets/db_password)" -e "SELECT 1"; do
    echo "Waiting for MariaDB to be ready..."
    sleep 5
done

# Check if WordPress is already installed
if ! wp core is-installed --path="/var/www/html/wordpress" --allow-root; then
    echo "WordPress not installed. Installing..."
    
    # Get admin credentials from secrets
    WP_ADMIN_USER=$(cat /run/secrets/credentials.txt | grep WP_ADMIN_USER | cut -d= -f2)
    WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials.txt | grep WP_ADMIN_PASSWORD | cut -d= -f2)
    WP_ADMIN_EMAIL=$(cat /run/secrets/credentials.txt | grep WP_ADMIN_EMAIL | cut -d= -f2)
    
    # Get regular user credentials from secrets
    WP_REGULAR_USER=$(cat /run/secrets/credentials.txt | grep WP_REGULAR_USER | cut -d= -f2)
    WP_REGULAR_PASSWORD=$(cat /run/secrets/credentials.txt | grep WP_REGULAR_PASSWORD | cut -d= -f2)
    WP_REGULAR_EMAIL=$(cat /run/secrets/credentials.txt | grep WP_REGULAR_EMAIL | cut -d= -f2)
    
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
    
    # Update plugins
    wp plugin update --all --path="/var/www/html/wordpress" --allow-root
    
    echo "WordPress installation completed!"
fi

# Set correct permissions
chown -R www-data:www-data /var/www/html/wordpress

# Start PHP-FPM
exec "$@"