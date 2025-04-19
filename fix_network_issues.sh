#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

# Function to check if a file exists in a container
check_file() {
    container=$1
    file=$2
    
    if docker exec $container test -f $file; then
        echo -e "${GREEN}✓ File $file exists in $container.${NC}"
        return 0
    else
        echo -e "${RED}✖ File $file does not exist in $container.${NC}"
        return 1
    fi
}

# Step 1: Fix WordPress PHP-FPM configuration
fix_wordpress_php_fpm() {
    print_header "Fixing WordPress PHP-FPM Configuration"
    
    # Backup the current configuration
    docker exec wordpress cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf.bak
    
    # Update the PHP-FPM configuration to listen on all interfaces
    echo "Updating PHP-FPM to listen on all interfaces (0.0.0.0:9000)..."
    docker exec wordpress sed -i 's/listen = .*/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf
    
    # Ensure www-data has proper permissions
    docker exec wordpress chown -R www-data:www-data /var/www/html/wordpress
    
    # Restart PHP-FPM
    docker exec wordpress kill -USR2 1
    
    echo -e "${GREEN}PHP-FPM configuration updated and service restarted.${NC}"
}

# Step 2: Fix MariaDB configuration
fix_mariadb_config() {
    print_header "Fixing MariaDB Configuration"
    
    # Backup the current configuration
    docker exec mariadb cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak
    
    # Ensure MariaDB is listening on all interfaces
    echo "Updating MariaDB to listen on all interfaces (0.0.0.0)..."
    docker exec mariadb sed -i 's/bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    
    # Restart MariaDB (note: this will restart the container as MariaDB is PID 1)
    docker restart mariadb
    
    echo -e "${GREEN}MariaDB configuration updated and service restarted.${NC}"
    
    # Wait for MariaDB to start up
    echo "Waiting for MariaDB to start up..."
    sleep 10
}

# Step 3: Fix NGINX configuration
fix_nginx_config() {
    print_header "Fixing NGINX Configuration"
    
    # Backup the current configuration
    docker exec nginx cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    
    # Ensure the fastcgi_pass directive is correct
    echo "Updating NGINX fastcgi_pass directive..."
    docker exec nginx sed -i 's/fastcgi_pass\s*wordpress:9000;/fastcgi_pass wordpress:9000;/' /etc/nginx/conf.d/default.conf
    
    # Reload NGINX
    docker exec nginx nginx -s reload
    
    echo -e "${GREEN}NGINX configuration updated and service reloaded.${NC}"
}

# Step 4: Fix WordPress wp-config.php
fix_wp_config() {
    print_header "Fixing WordPress Configuration"
    
    if check_file wordpress /var/www/html/wordpress/wp-config.php; then
        # Backup the current configuration
        docker exec wordpress cp /var/www/html/wordpress/wp-config.php /var/www/html/wordpress/wp-config.php.bak
        
        # Ensure DB_HOST is set correctly
        echo "Updating WordPress DB_HOST..."
        docker exec wordpress sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', 'mariadb' );/" /var/www/html/wordpress/wp-config.php
        
        echo -e "${GREEN}WordPress wp-config.php updated.${NC}"
    else
        echo -e "${YELLOW}wp-config.php not found, skipping this step.${NC}"
    fi
}

# Step 5: Fix network issues
fix_network_issues() {
    print_header "Fixing Network Issues"
    
    # Inspect the current network
    echo "Current network configuration:"
    docker network inspect inception_network
    
    # Recreate the network if needed
    echo "Recreating the Docker network..."
    docker network rm inception_network
    docker network create inception_network
    
    # Reconnect containers to the network
    for container in nginx wordpress mariadb; do
        echo "Reconnecting $container to inception_network..."
        docker network disconnect inception_network $container 2>/dev/null || true
        docker network connect inception_network $container
    done
    
    echo -e "${GREEN}Network reconfigured. All containers reconnected to inception_network.${NC}"
}

# Step 6: Install necessary diagnostic tools in containers
install_diagnostic_tools() {
    print_header "Installing Diagnostic Tools"
    
    for container in nginx wordpress mariadb; do
        echo "Installing tools in $container..."
        docker exec $container apt-get update 2>/dev/null
        docker exec $container apt-get install -y iputils-ping netcat-openbsd net-tools 2>/dev/null
    done
    
    echo -e "${GREEN}Diagnostic tools installed in all containers.${NC}"
}

# Step 7: Check connectivity after fixes
check_connectivity() {
    print_header "Checking Connectivity After Fixes"
    
    # Install diagnostic tools
    install_diagnostic_tools
    
    # Check if WordPress can reach MariaDB
    echo "Testing if WordPress can reach MariaDB..."
    if docker exec wordpress ping -c 2 mariadb; then
        echo -e "${GREEN}✓ WordPress can reach MariaDB.${NC}"
    else
        echo -e "${RED}✖ WordPress still cannot reach MariaDB.${NC}"
    fi
    
    # Check if WordPress can connect to MariaDB's port
    echo "Testing if WordPress can connect to MariaDB port 3306..."
    if docker exec wordpress nc -z -v mariadb 3306 2>&1; then
        echo -e "${GREEN}✓ WordPress can connect to MariaDB on port 3306.${NC}"
    else
        echo -e "${RED}✖ WordPress cannot connect to MariaDB on port 3306.${NC}"
    fi
    
    # Check if NGINX can reach WordPress
    echo "Testing if NGINX can reach WordPress..."
    if docker exec nginx ping -c 2 wordpress; then
        echo -e "${GREEN}✓ NGINX can reach WordPress.${NC}"
    else
        echo -e "${RED}✖ NGINX still cannot reach WordPress.${NC}"
    fi
    
    # Check if NGINX can connect to WordPress's port
    echo "Testing if NGINX can connect to WordPress port 9000..."
    if docker exec nginx nc -z -v wordpress 9000 2>&1; then
        echo -e "${GREEN}✓ NGINX can connect to WordPress on port 9000.${NC}"
    else
        echo -e "${RED}✖ NGINX cannot connect to WordPress on port 9000.${NC}"
    fi
}

# Step 8: Restart all containers
restart_containers() {
    print_header "Restarting All Containers"
    
    for container in mariadb wordpress nginx; do
        echo "Restarting $container..."
        docker restart $container
        sleep 5
    done
    
    echo -e "${GREEN}All containers restarted.${NC}"
}

# Main execution
print_header "Starting Network Issue Fixes"

echo "This script will fix network connectivity issues between containers."
echo -e "${YELLOW}Warning: This will modify configuration files and restart services.${NC}"
read -p "Do you want to continue? (y/n): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    # Execute all fixes
    fix_wordpress_php_fpm
    fix_mariadb_config
    fix_nginx_config
    fix_wp_config
    fix_network_issues
    restart_containers
    check_connectivity
    
    print_header "Fix Process Complete"
    echo -e "${GREEN}All fixes have been applied. Please test your setup now.${NC}"
    echo "If issues persist, please check the logs with 'docker logs <container_name>'."
else
    echo -e "${YELLOW}Fix process canceled.${NC}"
fi