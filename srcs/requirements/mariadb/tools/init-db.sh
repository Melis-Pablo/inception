#!/bin/bash
set -e

# Debug information
echo "Starting MariaDB initialization..."
echo "MYSQL_DATABASE: ${MYSQL_DATABASE}"
echo "MYSQL_USER: ${MYSQL_USER}"
echo "Data directory content before initialization:"
ls -la /var/lib/mysql

# Ensure proper permissions on data directory
chown -R mysql:mysql /var/lib/mysql
chmod 755 /var/lib/mysql

# If data directory is empty, initialize MariaDB
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB data directory is empty, initializing..."
    
    # Initialize MariaDB data directory
    echo "Running mysql_install_db..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    echo "Data directory after mysql_install_db:"
    ls -la /var/lib/mysql
    
    # Start MariaDB in the background
    echo "Starting temporary MariaDB server..."
    mysqld --user=mysql &
    MYSQL_PID=$!
    
    # Wait for MariaDB to start up
    echo "Waiting for MariaDB to be ready..."
    for i in {1..30}; do
        if mysqladmin ping -h localhost --silent; then
            echo "MariaDB is ready!"
            break
        fi
        echo "Waiting for MariaDB... (attempt $i/30)"
        sleep 2
        
        # Check if the process is still running
        if ! ps -p $MYSQL_PID > /dev/null; then
            echo "ERROR: MariaDB process died unexpectedly"
            echo "Checking error logs:"
            cat /var/log/mysql/error.log || echo "No error log found"
            exit 1
        fi
    done
    
    # Create database and users
    echo "Creating database '${MYSQL_DATABASE}'..."
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    
    # Read passwords from secrets
    DB_PASSWORD=$(cat /run/secrets/db_password)
    ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    
    echo "Creating user '${MYSQL_USER}'..."
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
    
    # Set root password and secure installation
    echo "Securing MariaDB installation..."
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Shutdown the temporary MariaDB server
    echo "Shutting down temporary MariaDB server..."
    mysqladmin --user=root --password="${ROOT_PASSWORD}" shutdown
    
    echo "MariaDB initialization completed!"
    echo "Data directory contents after initialization:"
    ls -la /var/lib/mysql
else
    echo "MariaDB data directory already contains database files"
    ls -la /var/lib/mysql/mysql
fi

echo "Starting MariaDB with command: $@"

# Start the main MariaDB process
exec "$@"