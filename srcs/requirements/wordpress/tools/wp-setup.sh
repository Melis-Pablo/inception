#!/bin/sh

# Add validation function at the start of the script
validate_admin_username() {
    local username="$1"

    # Convert username to lowercase for case-insensitive matching
    local username_lower=$(echo "$username" | tr '[:upper:]' '[:lower:]')

    # Check for prohibited patterns
    if echo "$username_lower" | grep -E "(admin|administrator)" > /dev/null; then
        echo "Error: Admin username cannot contain 'admin' or 'administrator' (case insensitive)"
        echo "Provided username: $username"
        return 1
    fi

    # Check length and valid characters
    if [ ${#username} -lt 3 ] || [ ${#username} -gt 60 ]; then
        echo "Error: Username must be between 3 and 60 characters long"
        return 1
    fi

    # Check for valid characters (alphanumeric, underscore, dash)
    if ! echo "$username" | grep -E "^[a-zA-Z0-9_-]+$" > /dev/null; then
        echo "Error: Username can only contain alphanumeric characters, underscores, and dashes"
        return 1
    fi

    return 0
}

# Add validation check before WordPress installation
echo "Validating admin username: $WORDPRESS_ADMIN_USER"
if ! validate_admin_username "$WORDPRESS_ADMIN_USER"; then
    echo "Invalid admin username. Exiting..."
    exit 1
fi

# Wait for MySQL to be ready
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 1
done

# Download WordPress if not exists
if [ ! -f "wp-config.php" ]; then
    # Download WordPress core
    wp core download --allow-root

    # Create wp-config.php
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root

    # Install WordPress
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Create additional user if required
    wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
        --role=author \
        --user_pass="$WORDPRESS_USER_PASSWORD" \
        --allow-root
fi

# Start PHP-FPM
exec "$@"