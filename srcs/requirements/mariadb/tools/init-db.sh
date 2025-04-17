#!/bin/bash
set -e

# If data directory is empty, initialize MariaDB
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    
    # Initialize MariaDB data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MariaDB in the background
    mysqld --user=mysql &
    
    # Wait for MariaDB to start up
    until mysqladmin ping -h localhost --silent; do
        echo "Waiting for MariaDB to be ready..."
        sleep 1
    done
    
    # Create database and users
    mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';"
    mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
    
    # Set root password and secure installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Shutdown the temporary MariaDB server
    mysqladmin -u root -p$(cat /run/secrets/db_root_password) shutdown
    
    echo "MariaDB initialization completed!"
fi

# Start the main MariaDB process
exec "$@"