#!/bin/sh

# Initialize MySQL data directory
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # Initial database setup
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start MySQL server in background
    mysqld --user=mysql --bootstrap << EOF
# Set root password
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$(cat /run/secrets/db_root_password)');
FLUSH PRIVILEGES;
# Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
# Create user and grant privileges
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
fi

# Execute CMD
exec "$@"
