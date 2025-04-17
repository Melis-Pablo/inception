# Docker Compose file location
COMPOSE_FILE = srcs/docker-compose.yml

# Data directory for volumes
DATA_DIR = /home/$(shell whoami)/data
WORDPRESS_DATA = $(DATA_DIR)/wordpress
MARIADB_DATA = $(DATA_DIR)/mariadb

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
RESET = \033[0m

all: setup build up

setup:
	@echo "$(GREEN)Creating data directories...$(RESET)"
	@mkdir -p $(WORDPRESS_DATA)
	@mkdir -p $(MARIADB_DATA)
	@echo "$(GREEN)Data directories created at:$(RESET)"
	@echo "WordPress: $(WORDPRESS_DATA)"
	@echo "MariaDB: $(MARIADB_DATA)"

build:
	@echo "$(GREEN)Building Docker images...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) build

up:
	@echo "$(GREEN)Starting containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Containers started! Website available at https://pmelis.42.fr$(RESET)"

down:
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(YELLOW)Containers stopped!$(RESET)"

clean: down
	@echo "$(RED)Cleaning up Docker resources...$(RESET)"
	@docker system prune -a --force
	@echo "$(RED)Docker resources cleaned!$(RESET)"

fclean: clean
	@echo "$(RED)Removing volumes and data directories...$(RESET)"
	@docker volume prune --force
	@sudo rm -rf $(DATA_DIR)
	@echo "$(RED)All data has been removed!$(RESET)"

re: fclean setup build up

status:
	@echo "$(GREEN)Container status:$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) ps

logs:
	@echo "$(GREEN)Container logs:$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) logs

help:
	@echo "$(GREEN)Available commands:$(RESET)"
	@echo "  make setup      - Create necessary directories"
	@echo "  make build      - Build Docker images"
	@echo "  make up         - Start containers"
	@echo "  make down       - Stop containers"
	@echo "  make clean      - Clean up Docker resources (except volumes)"
	@echo "  make fclean     - Remove everything including volumes and data"
	@echo "  make re         - Rebuild everything from scratch"
	@echo "  make status     - Show container status"
	@echo "  make logs       - Show container logs"

.PHONY: all setup build up down clean fclean re status logs help