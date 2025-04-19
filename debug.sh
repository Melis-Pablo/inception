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

# Install netcat if not present
check_and_install_netcat() {
    if ! command -v nc &> /dev/null; then
        echo -e "${YELLOW}Installing netcat for network diagnostics...${NC}"
        apt-get update && apt-get install -y netcat-openbsd
    fi
}

# Function for network debugging
debug_network() {
    container=$1
    
    print_header "Network Debug for $container"
    
    echo "Installing diagnostic tools if needed..."
    docker exec $container sh -c "apt-get update && apt-get install -y iputils-ping netcat-openbsd net-tools" 2>/dev/null || echo "Could not install tools in $container"
    
    echo "IP Address information:"
    docker exec $container ip addr
    
    echo "Routing information:"
    docker exec $container route -n
    
    echo "Open ports:"
    docker exec $container netstat -tulpn
    
    echo "DNS resolution check:"
    docker exec $container cat /etc/resolv.conf
}

# Function to check configuration files
check_config() {
    container=$1
    config_file=$2
    
    print_header "Checking $config_file on $container"
    docker exec $container cat $config_file 2>/dev/null || echo -e "${RED}File $config_file not found in $container${NC}"
}

# Function to test network connectivity between containers
test_connectivity() {
    source=$1
    target=$2
    port=$3
    
    print_header "Testing connectivity from $source to $target:$port"
    
    # Make sure netcat is installed
    docker exec $source sh -c "apt-get update && apt-get install -y netcat-openbsd" 2>/dev/null
    
    # Check if target is reachable via ping
    echo "Ping test:"
    docker exec $source ping -c 2 $target
    
    # Check if port is open
    echo "Port test with netcat:"
    docker exec $source nc -zv $target $port 2>&1 || echo -e "${RED}Connection to $target:$port failed${NC}"
    
    # Check DNS resolution
    echo "DNS resolution:"
    docker exec $source getent hosts $target || echo -e "${RED}DNS resolution for $target failed${NC}"
}

# Function to check for common issues
check_common_issues() {
    print_header "Checking for common issues"
    
    # Check if containers are on the same network
    echo "Network inspection:"
    docker network inspect inception_network
    
    # Check Docker logs
    echo "Docker daemon logs (last 20 lines):"
    journalctl -u docker.service | tail -20
    
    # Check if required volumes are mounted correctly
    echo "Volume mounts:"
    docker inspect -f '{{ .Mounts }}' mariadb
    docker inspect -f '{{ .Mounts }}' wordpress
    docker inspect -f '{{ .Mounts }}' nginx
}

# Function to check SELinux/AppArmor restrictions
check_security_restrictions() {
    print_header "Security Restrictions Check"
    
    # Check if AppArmor is active
    if command -v aa-status &> /dev/null; then
        echo "AppArmor status:"
        aa-status
    fi
    
    # Check if SELinux is active
    if command -v getenforce &> /dev/null; then
        echo "SELinux status:"
        getenforce
    fi
    
    # Check Docker security options
    echo "Docker security options:"
    docker info | grep -i security
}

# Check WordPress connection to MariaDB
debug_wordpress_db() {
    print_header "Debugging WordPress DB Connection"
    
    # Get MySQL credentials
    source ./srcs/.env
    DB_PASS=$(cat ./secrets/db_password.txt)
    
    echo "Testing connection from WordPress to MariaDB..."
    docker exec wordpress sh -c "apt-get update && apt-get install -y mariadb-client" 2>/dev/null
    docker exec wordpress mysql -h mariadb -u ${MYSQL_USER} -p${DB_PASS} -e "SHOW DATABASES;" || echo -e "${RED}Database connection failed${NC}"
    
    echo "Checking WordPress config:"
    docker exec wordpress cat /var/www/html/wordpress/wp-config.php | grep -E 'DB_HOST|DB_USER|DB_NAME'
}

# Check PHP-FPM configuration
debug_php_fpm() {
    print_header "Debugging PHP-FPM Configuration"
    
    echo "PHP-FPM process status:"
    docker exec wordpress ps aux | grep php-fpm
    
    echo "PHP-FPM configuration:"
    check_config wordpress /etc/php/7.4/fpm/pool.d/www.conf
    
    echo "Testing PHP-FPM socket/port:"
    docker exec wordpress netstat -tulpn | grep php-fpm
    
    echo "NGINX fastcgi configuration:"
    check_config nginx /etc/nginx/conf.d/default.conf
}

# Check directories and permissions
check_permissions() {
    print_header "Checking Directories and Permissions"
    
    echo "WordPress directory:"
    docker exec wordpress ls -la /var/www/html/
    
    echo "MariaDB data directory:"
    docker exec mariadb ls -la /var/lib/mysql/
    
    echo "NGINX webroot access:"
    docker exec nginx ls -la /var/www/html/wordpress/
}

# Check NGINX - WordPress communication
debug_nginx_wordpress() {
    print_header "Debugging NGINX - WordPress Communication"
    
    echo "NGINX configuration for FastCGI:"
    docker exec nginx grep -r "fastcgi_pass" /etc/nginx/
    
    echo "Testing connection from NGINX to WordPress:"
    test_connectivity nginx wordpress 9000
}

# Display network information for all containers
print_header "Network Information for All Containers"
for container in nginx wordpress mariadb; do
    echo "Container: $container"
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container
done

# Run network debug for each container
debug_network nginx
debug_network wordpress
debug_network mariadb

# Check configuration files
check_config nginx /etc/nginx/conf.d/default.conf
check_config wordpress /var/www/html/wordpress/wp-config.php
check_config mariadb /etc/mysql/mariadb.conf.d/50-server.cnf

# Test connectivity
test_connectivity nginx wordpress 9000
test_connectivity wordpress mariadb 3306

# Debug WordPress database connection
debug_wordpress_db

# Debug PHP-FPM configuration
debug_php_fpm

# Debug NGINX - WordPress communication
debug_nginx_wordpress

# Check permissions
check_permissions

# Check for common issues
check_common_issues

# Check security restrictions
check_security_restrictions

print_header "Recommendations"
echo "Based on common issues, try the following:"
echo "1. Make sure WordPress is listening on 0.0.0.0:9000, not just localhost"
echo "2. Check if MariaDB is accepting connections from other containers"
echo "3. Verify that the Docker network is properly configured"
echo "4. Ensure volume permissions are correct"
echo "5. Check for typos in configuration files"
echo "6. Restart the containers with 'make re'"