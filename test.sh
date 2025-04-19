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

# Function to check if a command is available
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✖ $1 is not installed. Please install it.${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed.${NC}"
        return 0
    fi
}

# Function to check if a Docker container is running
check_container() {
    if [ "$(docker ps -q -f name=$1)" ]; then
        echo -e "${GREEN}✓ Container $1 is running.${NC}"
        return 0
    else
        echo -e "${RED}✖ Container $1 is not running.${NC}"
        if [ "$(docker ps -a -q -f name=$1)" ]; then
            echo -e "${YELLOW}  Container exists but is not running. Checking logs:${NC}"
            docker logs $1 | tail -20
        fi
        return 1
    fi
}

# Function to check Docker volume
check_volume() {
    if docker volume inspect $1 &> /dev/null; then
        echo -e "${GREEN}✓ Volume $1 exists.${NC}"
        return 0
    else
        echo -e "${RED}✖ Volume $1 does not exist.${NC}"
        return 1
    fi
}

# Function to check Docker network
check_network() {
    if docker network inspect $1 &> /dev/null; then
        echo -e "${GREEN}✓ Network $1 exists.${NC}"
        return 0
    else
        echo -e "${RED}✖ Network $1 does not exist.${NC}"
        return 1
    fi
}

# Function to check if port is open on container
check_port() {
    container=$1
    port=$2
    
    if docker exec $container netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ Port $port is open on $container.${NC}"
        return 0
    else
        echo -e "${RED}✖ Port $port is not open on $container.${NC}"
        return 1
    fi
}

# Function to check communication between containers
check_communication() {
    source=$1
    target=$2
    port=$3
    
    if docker exec $source ping -c 1 $target &> /dev/null; then
        echo -e "${GREEN}✓ $source can reach $target.${NC}"
        if [ ! -z "$port" ]; then
            if docker exec $source nc -z $target $port &> /dev/null; then
                echo -e "${GREEN}✓ $source can connect to $target on port $port.${NC}"
            else
                echo -e "${RED}✖ $source cannot connect to $target on port $port.${NC}"
            fi
        fi
        return 0
    else
        echo -e "${RED}✖ $source cannot reach $target.${NC}"
        return 1
    fi
}

# Check system prerequisites
print_header "Checking System Prerequisites"
check_command docker
check_command docker-compose

# Check project structure
print_header "Checking Project Structure"
if [ -f "Makefile" ]; then
    echo -e "${GREEN}✓ Makefile exists.${NC}"
else
    echo -e "${RED}✖ Makefile is missing.${NC}"
fi

if [ -d "srcs" ]; then
    echo -e "${GREEN}✓ srcs directory exists.${NC}"
else
    echo -e "${RED}✖ srcs directory is missing.${NC}"
fi

if [ -f "srcs/docker-compose.yml" ]; then
    echo -e "${GREEN}✓ docker-compose.yml exists.${NC}"
else
    echo -e "${RED}✖ docker-compose.yml is missing.${NC}"
fi

if [ -f "srcs/.env" ]; then
    echo -e "${GREEN}✓ .env file exists.${NC}"
else
    echo -e "${RED}✖ .env file is missing.${NC}"
fi

# Check Docker status
print_header "Checking Docker Status"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker service is running.${NC}"
else
    echo -e "${RED}✖ Docker service is not running.${NC}"
    echo "Try starting it with: sudo systemctl start docker"
fi

# Check for Docker images
print_header "Checking Docker Images"
echo "Custom images for the project:"
docker images --format "{{.Repository}}" | grep -E "mariadb|wordpress|nginx" || echo -e "${YELLOW}No custom images found.${NC}"

# Check for running containers
print_header "Checking Containers"
check_container mariadb
check_container wordpress
check_container nginx

# Check volumes
print_header "Checking Volumes"
docker volume ls --format "{{.Name}}" | while read volume; do
    echo -e "${GREEN}✓ Volume $volume exists.${NC}"
done

# Check if MariaDB is properly initialized
print_header "Checking MariaDB"
if check_container mariadb; then
    echo "Testing MariaDB connection (this will use credentials from .env file):"
    source srcs/.env 2>/dev/null || { echo -e "${RED}Could not source .env file${NC}"; }
    
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo -e "${YELLOW}MYSQL_ROOT_PASSWORD not found in .env file.${NC}"
        echo "Enter MariaDB root password:"
        read -s MYSQL_ROOT_PASSWORD
    fi
    
    if docker exec mariadb mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" &>/dev/null; then
        echo -e "${GREEN}✓ Successfully connected to MariaDB.${NC}"
        echo "Databases:"
        docker exec mariadb mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
        
        if [ ! -z "$MYSQL_DATABASE" ]; then
            echo "WordPress database users:"
            docker exec mariadb mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT User, Host FROM mysql.user WHERE User != 'mariadb.sys' AND User != 'root' AND User != 'mysql';"
        fi
    else
        echo -e "${RED}✖ Failed to connect to MariaDB.${NC}"
    fi
fi

# Check WordPress configuration
print_header "Checking WordPress"
if check_container wordpress; then
    echo "WordPress files:"
    docker exec wordpress ls -la /var/www/html/
    
    echo "PHP-FPM status:"
    docker exec wordpress ps aux | grep php-fpm
fi

# Check Nginx configuration
print_header "Checking Nginx"
if check_container nginx; then
    echo "Nginx configuration:"
    docker exec nginx nginx -T 2>/dev/null || echo -e "${RED}Failed to test Nginx configuration.${NC}"
    
    echo "SSL certificate:"
    docker exec nginx ls -la /etc/nginx/ssl/ 2>/dev/null || echo -e "${YELLOW}No SSL certificates found in /etc/nginx/ssl/.${NC}"
    
    echo "Testing HTTPS connection (requires curl):"
    if curl --insecure -I https://localhost 2>/dev/null | grep -q "HTTP"; then
        echo -e "${GREEN}✓ HTTPS connection successful.${NC}"
    else
        echo -e "${RED}✖ HTTPS connection failed.${NC}"
    fi
fi

# Check network connectivity between containers
print_header "Checking Container Networking"
if check_container nginx && check_container wordpress && check_container mariadb; then
    check_communication nginx wordpress 9000
    check_communication wordpress mariadb 3306
fi

# Check Docker Compose configuration
print_header "Docker Compose Configuration"
echo "Service configuration:"
docker-compose -f srcs/docker-compose.yml config --services

# Check host entries
print_header "Checking /etc/hosts configuration"
if grep -q "127.0.0.1.*login.42.fr" /etc/hosts; then
    echo -e "${GREEN}✓ login.42.fr is configured in /etc/hosts.${NC}"
else
    echo -e "${RED}✖ login.42.fr is not configured in /etc/hosts.${NC}"
    echo "You should add: 127.0.0.1 login.42.fr"
fi

# Summary
print_header "Debug Summary"
echo -e "${YELLOW}If you're having issues:${NC}"
echo "1. Check the individual container logs with: docker logs <container_name>"
echo "2. Verify your Dockerfiles and configuration files"
echo "3. Make sure all environment variables are correctly set in .env"
echo "4. Restart containers with: make re"
echo "5. Check that volumes are properly mounted"

echo -e "\n${BLUE}For more advanced debugging:${NC}"
echo "- Inspect containers: docker inspect <container_name>"
echo "- Check container networks: docker network inspect <network_name>"
echo "- Access containers: docker exec -it <container_name> /bin/bash or /bin/sh"