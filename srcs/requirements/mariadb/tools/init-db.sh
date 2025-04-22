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

# Read passwords from secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

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
else
    echo "MariaDB data directory already contains database files"
    
    # Start MariaDB in the background to check/fix the setup
    echo "Starting temporary MariaDB server to verify database setup..."
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
    done
    
    # Check if our database and user exist, create them if not
    echo "Verifying database and user setup..."
    
    # Try to connect as root without password first
    if mysql -e "SELECT 'Root access working';" &>/dev/null; then
        echo "Root access without password - setting up root password"
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';"
        ROOT_AUTH="-p${ROOT_PASSWORD}"
    else
        # Try with password from secrets
        ROOT_AUTH="-p${ROOT_PASSWORD}"
        if ! mysql -uroot ${ROOT_AUTH} -e "SELECT 'Root access working';" &>/dev/null; then
            echo "WARNING: Could not authenticate as root to fix database setup"
            # Continue anyway as the server will start
        fi
    fi
    
    # Check and create database and user if we have root access
    if mysql -uroot ${ROOT_AUTH} -e "SELECT 'Root access working';" &>/dev/null; then
        # Check if database exists
        if ! mysql -uroot ${ROOT_AUTH} -e "USE \`${MYSQL_DATABASE}\`;" &>/dev/null; then
            echo "Database '${MYSQL_DATABASE}' does not exist, creating..."
            mysql -uroot ${ROOT_AUTH} -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
        else
            echo "Database '${MYSQL_DATABASE}' already exists"
        fi
        
        # Check if user exists
        USER_EXISTS=$(mysql -uroot ${ROOT_AUTH} -e "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}' AND Host='%';" | grep -c "${MYSQL_USER}" || true)
        if [ "$USER_EXISTS" -eq 0 ]; then
            echo "User '${MYSQL_USER}' does not exist, creating..."
            mysql -uroot ${ROOT_AUTH} -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
            mysql -uroot ${ROOT_AUTH} -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
            mysql -uroot ${ROOT_AUTH} -e "FLUSH PRIVILEGES;"
        else
            echo "User '${MYSQL_USER}' already exists, updating password..."
            mysql -uroot ${ROOT_AUTH} -e "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
            mysql -uroot ${ROOT_AUTH} -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
            mysql -uroot ${ROOT_AUTH} -e "FLUSH PRIVILEGES;"
        fi
    fi
    
    # Shutdown the temporary MariaDB server
    echo "Shutting down temporary MariaDB server..."
    mysqladmin -uroot ${ROOT_AUTH} shutdown || kill ${MYSQL_PID}
fi

echo "Data directory contents after setup:"
ls -la /var/lib/mysql

echo "Starting MariaDB with command: $@"

# Start the main MariaDB process
exec "$@"