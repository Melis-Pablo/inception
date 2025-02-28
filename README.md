# Inception

## 🐳 Project Overview

Inception is a system administration project focused on Docker containerization and services orchestration. The project involves creating a small-scale web infrastructure composed of multiple interconnected services, each running in its own container and managed through Docker Compose.

Unlike traditional deployment methods, Inception demonstrates the power of containerization by setting up a complete WordPress environment with separate containers for the web server, application, and database, all communicating through a custom Docker network.

![Docker Infrastructure](images/Diagram.png)

## 🏗️ Infrastructure Components

### Core Services
- **NGINX Container**: Front-facing web server with TLSv1.3 encryption
- **WordPress Container**: PHP-FPM application server
- **MariaDB Container**: Database server for WordPress

### Networking
- Custom Docker network connecting all containers
- NGINX as the only entry point through port 443 (HTTPS)
- Secure internal communication between services

### Data Persistence
- Volume for WordPress database
- Volume for WordPress files
- All data persisted in `/home/login/data` on the host machine

### Security Features
- TLSv1.3 encryption for all external connections
- Environment variables for sensitive configuration
- No hardcoded credentials in Dockerfiles
- Custom domain name configuration (login.42.fr)

## 🔧 Technical Implementation

### Docker Configuration

All services are built from custom Dockerfiles without using pre-built images (except for Alpine/Debian base):

```
Inception/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   └── tools/
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   └── tools/
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/
│           └── tools/
```

### Container Design Principles

Each container follows these principles:
- **Single Responsibility**: One service per container
- **Minimal Base Images**: Using Alpine/Debian for efficiency
- **Proper Init Systems**: Avoiding hacky solutions like `tail -f`
- **Automatic Restart**: Containers restart on failure
- **Environment Configuration**: All settings through environment variables

### NGINX Configuration

The NGINX container serves as the infrastructure's entry point:
- TLSv1.3 encryption with self-signed certificates
- Reverse proxy to WordPress container
- Security headers and optimized configurations

### WordPress Setup

The WordPress container runs PHP-FPM without a web server:
- PHP-FPM process management
- WordPress core installation and configuration
- Communication with MariaDB for data storage

### MariaDB Configuration

The MariaDB container provides database services:
- Initialized with WordPress database
- Multiple user accounts with appropriate permissions
- Data persistence through Docker volumes

## 🚀 Usage

### Prerequisites
- Docker and Docker Compose
- Virtual Machine environment
- Make

### Installation and Setup

```bash
# Clone the repository
git clone https://github.com/Melis-Pablo/inception.git
cd inception

# Start all services
make

# Access WordPress
# Navigate to https://login.42.fr in your browser
# (After setting up /etc/hosts to point to your VM's IP)
```

### Makefile Commands

| Command       | Description                                   |
|---------------|-----------------------------------------------|
| `make`        | Build and start all containers                |
| `make up`     | Start containers if already built             |
| `make down`   | Stop all containers                           |
| `make clean`  | Remove containers and networks                |
| `make fclean` | Remove everything (containers, images, volumes)|
| `make re`     | Rebuild entire infrastructure                 |

## 🛠️ Development Approach

### Container Orchestration

The project uses Docker Compose to define and manage the multi-container environment:
- Service definitions with build contexts
- Network configuration
- Volume mapping
- Environment variable injection
- Dependency management

### Configuration Management

Configuration is separated from code through:
- Environment variables stored in `.env` file
- Configuration files mounted into containers
- Docker secrets for sensitive information

### Initialization Scripts

Each container includes initialization scripts to:
- Set up the service on first run
- Configure the service based on environment variables
- Perform health checks
- Handle graceful shutdowns

## 📝 Learning Outcomes

This project provided in-depth experience with:

- **Docker Containerization**: Building custom Docker images and understanding container lifecycle
- **Service Orchestration**: Managing multiple interconnected services with Docker Compose
- **Network Configuration**: Setting up secure communication between containers
- **Data Persistence**: Implementing proper volume management for stateful applications
- **Web Server Configuration**: Configuring NGINX with TLS/SSL for secure communication
- **Database Management**: Setting up and securing a MariaDB database server
- **Environment Isolation**: Keeping development environments consistent and reproducible
- **Infrastructure as Code**: Defining complete infrastructure through configuration files

## ⚙️ Bonus Features

The project includes several additional services beyond the core requirements:

- **Redis Cache**: Performance optimization for WordPress
- **FTP Server**: File transfer access to WordPress content
- **Static Website**: Custom showcase site built with a non-PHP language
- **Adminer**: Database management interface
- **Custom Service**: Additional functionality with practical applications

## ⚠️ Note

For detailed project requirements, see the [inception.md](inception.md) file.

---

*This project is part of the 42 School Common Core curriculum.*