#!/bin/bash
set -e

# Read passwords from secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Ensure proper permissions on data directory
chown -R mysql:mysql /var/lib/mysql
chmod 755 /var/lib/mysql

# Initialize MariaDB if data directory is empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MariaDB temporarily
    mysqld --user=mysql &
    MYSQL_PID=$!
    
    # Wait for MariaDB to start
    until mysqladmin ping -h localhost --silent; do
        sleep 1
        # Check if process is still alive
        if ! ps -p $MYSQL_PID > /dev/null; then
            echo "MariaDB process died"
            exit 1
        fi
    done
    
    # Create database and users
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
    
    # Secure the installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Shutdown the temporary server
    mysqladmin --user=root --password="${ROOT_PASSWORD}" shutdown
    echo "MariaDB initialization completed"
else
    echo "MariaDB data directory already exists"
fi

# Start the main MariaDB process
exec "$@"