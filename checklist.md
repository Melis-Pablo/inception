# Inception Project Checklist

## Setup and Environment
- [ ] Project is running on a Virtual Machine
- [ ] All necessary software is installed (Docker, Docker Compose)
- [ ] User is added to docker group to avoid using sudo

## Directory Structure
- [ ] All configuration files are placed in a `srcs` folder
- [ ] Makefile exists at the root directory
- [ ] `.env` file is present in the `srcs` directory
- [ ] `docker-compose.yml` is present in the `srcs` directory
- [ ] Directory structure follows project requirements:
  - [ ] `srcs/requirements/mariadb/` directory exists
  - [ ] `srcs/requirements/nginx/` directory exists
  - [ ] `srcs/requirements/wordpress/` directory exists
  - [ ] Each service directory contains a Dockerfile
  - [ ] Each service directory contains conf/ and tools/ subdirectories

## Docker Compose Configuration
- [ ] Docker Compose file is properly configured
- [ ] Services are correctly defined (nginx, wordpress, mariadb)
- [ ] Volumes are properly configured
- [ ] Networks are properly configured
- [ ] Container restart policy is set (must restart on crash)
- [ ] No usage of network: host, --link, or links: (forbidden)
- [ ] Environment variables are properly referenced
- [ ] Secrets are properly configured

## Docker Containers
- [ ] NGINX container is running properly
- [ ] WordPress container is running properly
- [ ] MariaDB container is running properly
- [ ] Each container has the same name as its corresponding service
- [ ] Each service runs in a dedicated container
- [ ] All containers restart automatically after a crash
- [ ] No prohibited infinite loop methods used as entrypoint or command:
  - [ ] No `tail -f` commands
  - [ ] No `bash` as the main process
  - [ ] No `sleep infinity` commands
  - [ ] No `while true` loops

## Docker Images
- [ ] All Docker images are built from penultimate stable version of Alpine or Debian
- [ ] No `latest` tag is used (prohibited)
- [ ] Custom Dockerfiles exist for each service
- [ ] No pre-made Docker images or services from DockerHub used (except base Alpine/Debian)

## NGINX Configuration
- [ ] NGINX is configured with TLSv1.2 or TLSv1.3 only
- [ ] SSL certificate is properly created and configured
- [ ] NGINX is accessible only via port 443
- [ ] NGINX properly forwards requests to WordPress
- [ ] NGINX is the only entry point into the infrastructure

## WordPress Configuration
- [ ] WordPress is installed with php-fpm
- [ ] PHP-FPM is correctly configured
- [ ] WordPress website is accessible through the domain
- [ ] WordPress properly connects to MariaDB
- [ ] Two WordPress users are created:
  - [ ] One administrator user
  - [ ] One regular user
- [ ] Admin username does NOT contain 'admin', 'Admin', 'administrator', or 'Administrator'

## MariaDB Configuration
- [ ] MariaDB server is running correctly
- [ ] WordPress database is created
- [ ] Database user is created with correct permissions
- [ ] Database is properly configured for WordPress

## Network Configuration
- [ ] Docker network is created correctly
- [ ] Containers can communicate with each other
- [ ] Network line is present in docker-compose.yml

## Volumes Configuration
- [ ] WordPress database volume is created and mounted correctly
- [ ] WordPress files volume is created and mounted correctly
- [ ] Volumes are available in /home/login/data folder (with login replaced by your username)
- [ ] Data persists after container restarts (make down && make up)

## Environment Variables and Secrets
- [ ] Environment variables are properly used
- [ ] No passwords are present in Dockerfiles
- [ ] .env file contains all necessary variables:
  - [ ] DOMAIN_NAME
  - [ ] MYSQL_DATABASE
  - [ ] MYSQL_USER
  - [ ] Data paths
  - [ ] WordPress configuration
- [ ] Docker secrets or other secure methods are used for sensitive data
- [ ] Proper .gitignore file to exclude sensitive data

## Domain Configuration
- [ ] Domain name is set to login.42.fr (with login replaced by your username)
- [ ] Domain points to your local IP address (entry in /etc/hosts)
- [ ] Domain is properly configured in NGINX

## Security
- [ ] No credentials, API keys, or passwords are stored in Dockerfiles
- [ ] Passwords and sensitive information are stored in secure locations
- [ ] Credentials are ignored by git (.gitignore)
- [ ] No sensitive information is exposed in container environment

## Bonus Items (Optional)
- [ ] Redis cache is set up for WordPress
- [ ] FTP server container points to WordPress volume
- [ ] Simple static website (not in PHP) is created
- [ ] Adminer is set up
- [ ] Additional service is implemented with justification
- [ ] Each bonus service has its own Dockerfile and container

## Manual Tests with Instructions

### WordPress Users Test
- [ ] Test admin user:
  1. Access your WordPress site at https://your_login.42.fr/wp-admin
  2. Login with admin credentials from secrets/credentials.txt
  3. Verify this user has admin privileges (can access all Dashboard options)
  4. Confirm the username doesn't contain "admin" or "administrator" (in any case variation)
- [ ] Test regular user:
  1. Access WordPress with regular user credentials from secrets/credentials.txt
  2. Verify this user has author (not admin) privileges
  3. Check they can create posts but cannot modify site settings

### Data Persistence Test
- [ ] Test MariaDB data persistence:
  1. Login to WordPress admin and create a new post
  2. Run `make down` to stop all containers
  3. Run `make up` to restart containers
  4. Check if your post still exists
  5. Verify by checking files in /home/your_login/data/mariadb
- [ ] Test WordPress data persistence:
  1. Upload a media file to WordPress
  2. Run `make down` to stop all containers
  3. Run `make up` to restart containers
  4. Verify media file is still accessible
  5. Check files in /home/your_login/data/wordpress

### Container Auto-restart Test
- [ ] Test automatic restart:
  1. Find container IDs: `docker ps`
  2. Kill a container: `docker kill [container-id]`
  3. Wait a few seconds and run `docker ps` again
  4. Verify container has automatically restarted
  5. Repeat for each container (nginx, mariadb, wordpress)

### Security Tests
- [ ] Test NGINX as single entry point:
  1. Verify only port 443 is exposed: `docker ps | grep -E 'PORTS'`
  2. Try to access other ports directly (e.g., 3306 for MariaDB, 9000 for PHP-FPM)
  3. These should not be accessible from outside
- [ ] Test TLS version restriction:
  1. Run: `nmap --script ssl-enum-ciphers -p 443 your_login.42.fr`
  2. Verify only TLSv1.2/TLSv1.3 is supported (no TLSv1.0/1.1)
  3. Alternative: `openssl s_client -connect your_login.42.fr:443 -tls1_1`
     This should fail for TLSv1.1 but succeed for TLSv1.2

### Environment Variables and Secrets
- [ ] Verify environment variables:
  1. Check container environment: `docker exec wordpress env`
  2. Confirm variables from .env are present
  3. Verify no plaintext passwords are visible in environment
- [ ] Test secrets access:
  1. Check if secrets are properly mounted: `docker exec wordpress ls -la /run/secrets/`
  2. Verify credentials file is accessible to the container

## Testing and Validation
- [ ] All containers start properly with `make up`
- [ ] Website is accessible via https://login.42.fr
- [ ] WordPress admin panel is accessible
- [ ] WordPress login works with both users
- [ ] Database connection is stable
- [ ] Data persists between container restarts
- [ ] All containers restart automatically after being manually stopped
- [ ] No error messages in container logs

## Final Review
- [ ] Project structure matches requirements exactly
- [ ] All mandatory features are implemented
- [ ] Code is clean and well-organized
- [ ] Documentation is complete
- [ ] All tests pass
- [ ] Project is ready for evaluation