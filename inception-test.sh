#!/bin/bash

# Inception Project Requirements Test Script
# This script tests if the Inception project meets all the required specifications

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get current user for path and domain settings
USER=$(whoami)
DOMAIN="${USER}.42.fr"
DATA_PATH="/home/${USER}/data"

# Print header
print_header() {
    echo -e "\n${BLUE}========== $1 ==========${NC}"
}

# Print success/failure message
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        if [ ! -z "$3" ]; then
            echo -e "${YELLOW}  $3${NC}"
        fi
    fi
    return $1
}

# Check if command exists
check_command() {
    command -v $1 > /dev/null 2>&1
    print_result $? "Command $1 exists" "Install with: sudo apt-get install $1"
}

# Check if file exists
check_file() {
    [ -f "$1" ]
    print_result $? "File $1 exists" "Create this file according to project specs"
}

# Check if directory exists
check_dir() {
    [ -d "$1" ]
    print_result $? "Directory $1 exists" "Create this directory according to project specs"
}

# Check if string is in file
check_in_file() {
    grep -q "$1" "$2" 2>/dev/null
    print_result $? "$1 configured in $2" "Add this configuration to $2"
}

# Check if container is running
check_container() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
    print_result $? "Container $1 is running" "Start with: make up"
}

# VM Environment Check
print_header "VM Environment Check"
if [ -f /proc/cpuinfo ]; then
    VIRTUALIZATION=$(grep -i "hypervisor\|virtual" /proc/cpuinfo || echo "none")
    if [[ "$VIRTUALIZATION" != "none" ]]; then
        echo -e "${GREEN}✓ Running inside a virtual machine${NC}"
    else
        echo -e "${YELLOW}⚠ Not detected as running in a VM - make sure this is running in the required environment${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Unable to determine if running in a VM - verify manually${NC}"
fi

# Directory Structure Check
print_header "Directory Structure Check"
check_dir "srcs"
check_file "Makefile"
check_file "srcs/docker-compose.yml"
check_file "srcs/.env"
check_dir "srcs/requirements"
check_dir "srcs/requirements/mariadb"
check_dir "srcs/requirements/nginx"
check_dir "srcs/requirements/wordpress"
check_file "srcs/requirements/mariadb/Dockerfile"
check_file "srcs/requirements/nginx/Dockerfile"
check_file "srcs/requirements/wordpress/Dockerfile"

# Docker Tools Check
print_header "Docker Tools Check"
check_command "docker"
check_command "docker-compose"
docker info > /dev/null 2>&1
print_result $? "Docker daemon is running" "Start Docker with: sudo systemctl start docker"

# Check if current user is in docker group
if groups | grep -q '\bdocker\b'; then
    echo -e "${GREEN}✓ Current user is in docker group${NC}"
else
    echo -e "${YELLOW}⚠ Current user is not in docker group - add with: sudo usermod -aG docker $USER${NC}"
fi

# Docker Compose Configuration Check
print_header "Docker Compose Configuration Check"
check_in_file "version:" "srcs/docker-compose.yml"
check_in_file "networks:" "srcs/docker-compose.yml"
check_in_file "volumes:" "srcs/docker-compose.yml"
check_in_file "restart:" "srcs/docker-compose.yml"

# Verify no forbidden network configurations
if grep -q 'network: host\|links:\|--link' "srcs/docker-compose.yml"; then
    print_result 1 "No forbidden network configurations" "Remove network: host, --link, or links: from docker-compose.yml"
else
    print_result 0 "No forbidden network configurations"
fi

# Environmental Variables Check
print_header "Environment Variables Check"
check_file "srcs/.env"
check_in_file "DOMAIN_NAME=" "srcs/.env"
check_in_file "MYSQL_DATABASE=" "srcs/.env"
check_in_file "MYSQL_USER=" "srcs/.env"
check_in_file "DATA_PATH=" "srcs/.env"

# Check .env is configured with correct paths
DATA_PATH_CONFIG=$(grep "DATA_PATH=" "srcs/.env" | cut -d= -f2)
if [[ "$DATA_PATH_CONFIG" == *"$USER"* ]]; then
    print_result 0 "DATA_PATH contains correct username"
else
    print_result 1 "DATA_PATH contains correct username" "Update DATA_PATH in .env to include your username"
fi

# Secrets Check
print_header "Secrets Check"
check_dir "secrets"
check_file "secrets/db_password.txt"
check_file "secrets/db_root_password.txt"
check_file "secrets/credentials.txt"

# Check .gitignore to make sure secrets aren't committed
check_file ".gitignore"
check_in_file "secrets/" ".gitignore"
check_in_file ".env" ".gitignore"

# Docker Containers Status Check
print_header "Docker Containers Status Check"
docker ps > /dev/null 2>&1
if [ $? -eq 0 ]; then
    check_container "nginx"
    check_container "mariadb"
    check_container "wordpress"
    
    # Check container naming matches service naming
    for service in nginx mariadb wordpress; do
        if docker ps --format '{{.Names}}' | grep -q "^$service$"; then
            print_result 0 "$service container name matches service name"
        else
            print_result 1 "$service container name matches service name" "Container names must match service names"
        fi
    done
else
    echo -e "${YELLOW}⚠ Docker is not running or requires sudo. Run with sudo or check Docker daemon${NC}"
fi

# Docker Images Check
print_header "Docker Images Check"
for service in nginx mariadb wordpress; do
    docker images | grep -q "$service"
    print_result $? "$service image exists" "Build with: make build"
    
    # Check if using latest tag (prohibited)
    if docker images | grep "$service" | grep -q 'latest'; then
        print_result 1 "$service image avoids 'latest' tag" "Don't use 'latest' tag, use specific version"
    else
        print_result 0 "$service image avoids 'latest' tag"
    fi
    
    # Get the image ID
    IMAGE_ID=$(docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "$service" | awk '{print $2}')
    
    # Check if Dockerfile contains proper base image
    DOCKERFILE_PATH="srcs/requirements/$service/Dockerfile"
    if grep -q -E '^FROM (debian:(bullseye|buster)|alpine:[0-9]+\.[0-9]+)' "$DOCKERFILE_PATH"; then
        print_result 0 "$service uses proper base image"
    else
        print_result 1 "$service uses proper base image" "Use Alpine or Debian penultimate stable version (bullseye/buster for Debian)"
    fi
done

# Network Configuration Check
print_header "Network Configuration Check"
docker network ls | grep -q "inception_network"
print_result $? "inception_network exists" "Make sure network is created with proper name"

if docker network inspect inception_network &>/dev/null; then
    for service in nginx mariadb wordpress; do
        if docker inspect "$service" 2>/dev/null | grep -q "inception_network"; then
            print_result 0 "$service is connected to inception_network"
        else
            print_result 1 "$service is connected to inception_network" "Make sure $service is connected to the network"
        fi
    done
fi

# Volumes Check
print_header "Volumes Configuration Check"
docker volume ls | grep -q "db_data"
print_result $? "MariaDB volume exists" "Check volume configuration in docker-compose.yml"

docker volume ls | grep -q "wp_data"
print_result $? "WordPress volume exists" "Check volume configuration in docker-compose.yml"

check_dir "${DATA_PATH}"
check_dir "${DATA_PATH}/mariadb"
check_dir "${DATA_PATH}/wordpress"

# NGINX Configuration Check
print_header "NGINX Configuration Check"
if docker exec nginx nginx -t &>/dev/null; then
    print_result 0 "NGINX configuration is valid"
    
    # Check SSL protocols
    if docker exec nginx grep -q 'ssl_protocols TLSv1.2 TLSv1.3' /etc/nginx/nginx.conf 2>/dev/null || 
       docker exec nginx grep -q 'ssl_protocols TLSv1.2 TLSv1.3' /etc/nginx/conf.d/default.conf 2>/dev/null; then
        print_result 0 "NGINX is configured with TLSv1.2/TLSv1.3 only"
    else
        print_result 1 "NGINX is configured with TLSv1.2/TLSv1.3 only" "Configure NGINX to use only TLSv1.2/TLSv1.3"
    fi
    
    # Check SSL certificate
    docker exec nginx ls -la /etc/nginx/ssl/nginx.crt &>/dev/null
    print_result $? "SSL certificate exists"
    
    docker exec nginx ls -la /etc/nginx/ssl/nginx.key &>/dev/null
    print_result $? "SSL key exists"
    
    # Check port 443
    docker port nginx | grep -q '443'
    print_result $? "NGINX exposes port 443" "Configure NGINX to expose port 443"
else
    print_result 1 "NGINX configuration is valid" "Check NGINX configuration for errors"
fi

# MariaDB Configuration Check
print_header "MariaDB Configuration Check"
if docker exec mariadb mysqladmin ping -h localhost --silent &>/dev/null; then
    print_result 0 "MariaDB server is responding"
    
    # Try to check database existence
    DB_NAME=$(grep MYSQL_DATABASE srcs/.env | cut -d= -f2)
    DB_USER=$(grep MYSQL_USER srcs/.env | cut -d= -f2)
    
    # This will need manual verification or mysql credentials
    echo -e "${YELLOW}⚠ Database configuration should be manually verified:${NC}"
    echo -e "${YELLOW}  - Verify database '$DB_NAME' exists${NC}"
    echo -e "${YELLOW}  - Verify user '$DB_USER' exists with correct permissions${NC}"
    echo -e "${YELLOW}  - Verify WordPress tables are created${NC}"
else
    print_result 1 "MariaDB server is responding" "Check MariaDB configuration and logs"
fi

# WordPress Configuration Check
print_header "WordPress Configuration Check"
if docker exec wordpress php -v &>/dev/null; then
    print_result 0 "PHP is installed in WordPress container"
    
    # Check PHP-FPM
    docker exec wordpress ps aux | grep -q 'php-fpm'
    print_result $? "PHP-FPM is running in WordPress container" "Make sure PHP-FPM is installed and running"
    
    # Check WordPress files
    docker exec wordpress ls -la /var/www/html/wordpress &>/dev/null
    print_result $? "WordPress files exist" "Check WordPress installation"
    
    # Check WordPress config
    docker exec wordpress ls -la /var/www/html/wordpress/wp-config.php &>/dev/null
    print_result $? "WordPress config exists" "Check WordPress configuration"
    
    # Note about WordPress users
    echo -e "${YELLOW}⚠ WordPress users should be manually verified:${NC}"
    echo -e "${YELLOW}  - Verify two users exist (one admin, one regular)${NC}"
    echo -e "${YELLOW}  - Verify admin username doesn't contain 'admin', 'Admin', 'administrator', etc.${NC}"
else
    print_result 1 "PHP is installed in WordPress container" "Check WordPress container configuration"
fi

# Container Initialization Method Check
print_header "Container Running Method Check"
for service in nginx mariadb wordpress; do
    # Check for prohibited methods
    if docker inspect $service 2>/dev/null | grep -E 'Cmd|Entrypoint' | grep -E 'tail -f|bash$|sleep infinity|while true' &>/dev/null; then
        print_result 1 "$service uses proper initialization method" "Don't use tail -f, bash, sleep infinity, or while true"
    else
        print_result 0 "$service uses proper initialization method"
    fi
    
    # Check restart policy
    if docker inspect $service 2>/dev/null | grep -q '"RestartPolicy":{"Name":"unless-stopped\|always\|on-failure"'; then
        print_result 0 "$service has proper restart policy"
    else
        print_result 1 "$service has proper restart policy" "Set restart policy to unless-stopped, always, or on-failure"
    fi
done

# Container Auto-Restart Test
print_header "Container Auto-Restart Test"

# Function to test if a container restarts after crash
test_container_restart() {
    local container=$1
    local process_pattern=$2
    local signal=$3
    
    echo -e "${YELLOW}Testing auto-restart for $container...${NC}"
    
    # Get current container ID for later comparison
    local CURRENT_ID=$(docker ps -q -f name=$container)
    local START_TIME=$(docker inspect --format='{{.State.StartedAt}}' $container)
    
    if [ -z "$CURRENT_ID" ]; then
        echo -e "${RED}✗ $container is not running${NC}"
        return 1
    fi
    
    echo -e "  ${CYAN}Container started at: $START_TIME${NC}"
    
    # Find the process to kill
    local PROCESS_PID=$(docker exec $container ps -ef | grep "$process_pattern" | grep -v grep | awk '{print $2}' | head -1)
    
    if [ -z "$PROCESS_PID" ]; then
        echo -e "${RED}✗ Process matching '$process_pattern' not found in $container${NC}"
        return 1
    fi
    
    echo -e "  ${CYAN}Found process matching '$process_pattern' with PID $PROCESS_PID${NC}"
    echo -e "  ${CYAN}Sending signal $signal to crash the process at $(date +"%T.%3N")...${NC}"
    
    # Crash the process with the specified signal
    docker exec $container kill -$signal $PROCESS_PID
    
    # Immediately check container status
    echo -e "  ${CYAN}Monitoring container status:${NC}"
    
    # Monitor container status continuously with timestamps
    local max_checks=30
    local restart_detected=false
    local down_detected=false
    
    for ((i=1; i<=max_checks; i++)); do
        # Get current status
        local STATUS=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)
        local HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null)
        
        # Format timestamp for logging
        local TIMESTAMP=$(date +"%T.%3N")
        
        # Check if container is in restarting state or process is missing
        if [[ "$STATUS" == "restarting" ]]; then
            echo -e "  ${RED}[$TIMESTAMP] Container is restarting${NC}"
            down_detected=true
        elif [[ "$STATUS" == "running" ]]; then
            # Check if process is running
            if docker exec $container ps -ef | grep "$process_pattern" | grep -v grep > /dev/null; then
                if [[ "$down_detected" == "true" ]]; then
                    echo -e "  ${GREEN}[$TIMESTAMP] Process is back up and running${NC}"
                    restart_detected=true
                    break
                else
                    echo -e "  ${YELLOW}[$TIMESTAMP] Container still running, waiting for restart${NC}"
                fi
            else
                echo -e "  ${RED}[$TIMESTAMP] Container running but process is down${NC}"
                down_detected=true
            fi
        else
            echo -e "  ${RED}[$TIMESTAMP] Container status: $STATUS${NC}"
            down_detected=true
        fi
        
        sleep 1
    done
    
    # After restart, get new details
    local NEW_START_TIME=$(docker inspect --format='{{.State.StartedAt}}' $container)
    local RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' $container)
    
    echo -e "  ${CYAN}Container restart count: $RESTART_COUNT${NC}"
    echo -e "  ${CYAN}New start time: $NEW_START_TIME${NC}"
    
    if [[ "$START_TIME" != "$NEW_START_TIME" ]]; then
        echo -e "  ${GREEN}✓ Confirmed: Container was restarted (start time changed)${NC}"
    fi
    
    if [[ "$restart_detected" == "true" || "$RESTART_COUNT" -gt 0 ]]; then
        echo -e "${GREEN}✓ Container $container successfully recovered from crash${NC}"
        
        # Verify the service is actually working
        case $container in
            nginx)
                docker exec $container nginx -t &>/dev/null
                local service_check=$?
                ;;
            mariadb)
                docker exec $container mysqladmin ping -h localhost --silent &>/dev/null
                local service_check=$?
                ;;
            wordpress)
                docker exec $container php-fpm7.4 -t &>/dev/null
                local service_check=$?
                ;;
            *)
                local service_check=1
                ;;
        esac
        
        if [ $service_check -eq 0 ]; then
            echo -e "${GREEN}✓ $container service is functioning after restart${NC}"
            return 0
        else
            echo -e "${RED}✗ $container service is not functioning after restart${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Could not confirm restart of $container${NC}"
        return 1
    fi
}

# Test each container with correct process patterns
echo -e "\n${BLUE}Testing NGINX container restart...${NC}"
test_container_restart "nginx" "nginx: master process" "11"  # SIGSEGV

echo -e "\n${BLUE}Testing MariaDB container restart...${NC}"
test_container_restart "mariadb" "mysqld" "11"  # SIGSEGV

echo -e "\n${BLUE}Testing WordPress container restart...${NC}"
test_container_restart "wordpress" "php-fpm" "11"  # SIGSEGV
# Summarize container restart test results
echo -e "\n${CYAN}Container Auto-Restart Test Summary:${NC}"
echo -e "${CYAN}The containers should automatically restart after a crash${NC}"
echo -e "${CYAN}This is required by the Inception project specifications${NC}"
echo -e "${CYAN}If any tests failed, check your docker-compose.yml restart policy${NC}"

# Domain Configuration Check
print_header "Domain Configuration Check"
if grep -q "${DOMAIN}" /etc/hosts; then
    print_result 0 "Domain is configured in /etc/hosts"
else
    print_result 1 "Domain is configured in /etc/hosts" "Add with: echo '127.0.0.1 ${DOMAIN}' | sudo tee -a /etc/hosts"
fi

# Website Accessibility Check
print_header "Website Accessibility Check"
if command -v curl &>/dev/null; then
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://${DOMAIN} 2>/dev/null)
    if [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]]; then
        print_result 0 "Website is accessible via HTTPS (status code: $HTTP_CODE)"
    else
        print_result 1 "Website is accessible via HTTPS (got: $HTTP_CODE)" "Check NGINX and WordPress configurations"
    fi
else
    echo -e "${YELLOW}⚠ curl not installed, can't test website accessibility${NC}"
    echo -e "${YELLOW}  Install with: sudo apt-get install curl${NC}"
fi

# Security Check
print_header "Security Check"
for service in mariadb nginx wordpress; do
    if grep -i -E 'password|secret|credentials' "srcs/requirements/$service/Dockerfile" &>/dev/null; then
        print_result 1 "No passwords in $service Dockerfile" "Remove passwords from Dockerfile and use environment variables"
    else
        print_result 0 "No passwords in $service Dockerfile"
    fi
done

# Final Summary
print_header "Requirements Summary"
echo -e "${CYAN}Mandatory Checks:${NC}"
echo -e "${CYAN}1. Project is running inside a VM${NC}"
echo -e "${CYAN}2. All required directories and files exist${NC}"
echo -e "${CYAN}3. Three containers: NGINX, WordPress, MariaDB${NC}"
echo -e "${CYAN}4. Each container uses its own custom Dockerfile${NC}"
echo -e "${CYAN}5. NGINX uses TLSv1.2/TLSv1.3 only and is accessible via port 443${NC}"
echo -e "${CYAN}6. WordPress uses php-fpm and connects to MariaDB${NC}"
echo -e "${CYAN}7. Two volumes set up correctly${NC}"
echo -e "${CYAN}8. Docker network set up correctly${NC}"
echo -e "${CYAN}9. Containers restart automatically${NC}"
echo -e "${CYAN}10. Domain name resolves correctly${NC}"
echo -e "${CYAN}11. Environment variables used correctly, no passwords in Dockerfiles${NC}"
echo -e "${CYAN}12. No prohibited initialization methods used${NC}"
echo -e "\n${YELLOW}Important manual checks:${NC}"
echo -e "${YELLOW}1. Verify WordPress has two users (one admin, one regular)${NC}"
echo -e "${YELLOW}2. Admin username must NOT contain 'admin', 'Admin', 'administrator', etc.${NC}"
echo -e "${YELLOW}3. Verify data persists after container restart (make down && make up)${NC}"
echo -e "${YELLOW}4. Verify all images use the penultimate stable version of Alpine or Debian${NC}"
echo -e "${YELLOW}5. Test that all containers restart automatically after a crash${NC}"

echo -e "\n${PURPLE}============================================================${NC}"
echo -e "${PURPLE}Test script completed! Address any issues marked with ✗ before submission.${NC}"
echo -e "${PURPLE}============================================================${NC}"