# Docker Compose file location
COMPOSE_FILE = srcs/docker-compose.yml

# Data directory for volumes
USER ?= $(shell whoami)
DOMAIN_NAME = $(USER).42.fr
DATA_PATH = /home/$(USER)/data
DB_PATH = $(DATA_PATH)/mariadb
WP_PATH = $(DATA_PATH)/wordpress

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
RESET = \033[0m

all: setup build up

setup:
	@echo "$(GREEN)Creating data directories...$(RESET)"
	@sudo mkdir -p $(DB_PATH) $(WP_PATH)
	@echo "$(YELLOW)Setting up permissions...$(RESET)"
	@sudo chmod -R 775 $(DB_PATH) $(WP_PATH)
	@sudo chown -R $(USER):$(USER) $(DATA_PATH)
	@echo "$(GREEN)Directory setup complete!$(RESET)"

build:
	@echo "$(GREEN)Building Docker images...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) build || (echo "$(RED)Failed to build images!$(RESET)" && exit 1)

up:
	@if [ ! -d "$(DB_PATH)" ] || [ ! -d "$(WP_PATH)" ]; then \
		printf "$(RED)Volumes not set up. Running setup...$(RESET)\n" && \
		$(MAKE) setup; \
	fi
	@echo "$(GREEN)Starting containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) up -d || (echo "$(RED)Failed to start containers!$(RESET)" && exit 1)
	@echo "$(GREEN)Containers started! Website available at https://$(DOMAIN_NAME)$(RESET)"

down:
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) down || (echo "$(RED)Failed to stop containers!$(RESET)" && exit 1)
	@echo "$(YELLOW)Containers stopped!$(RESET)"

clean: down
	@echo "$(RED)Cleaning up Docker resources...$(RESET)"
	@docker system prune -a --force
	@echo "$(RED)Docker resources cleaned!$(RESET)"

fclean: clean
	@echo "$(RED)Removing volumes and data directories...$(RESET)"
	@docker volume prune --force
	@if [ -d "$(DATA_PATH)" ]; then \
		sudo rm -rf $(DATA_PATH); \
	fi
	@echo "$(RED)All data has been removed!$(RESET)"

re: fclean all

test-volumes:
	@printf "$(YELLOW)Testing volume persistence...$(RESET)\n"
	@docker-compose -f $(COMPOSE_FILE) ps | grep -q "Up" || \
		(printf "$(RED)Containers are not running!$(RESET)\n" && exit 1)
	@printf "Testing MariaDB volume..."
	@test -d $(DB_PATH)/mysql || \
		(printf "$(RED)MariaDB data not found!$(RESET)\n" && exit 1)
	@printf "$(GREEN)OK$(RESET)\n"
	@printf "Testing WordPress volume..."
	@test -d $(WP_PATH) || \
		(printf "$(RED)WordPress data not found!$(RESET)\n" && exit 1)
	@printf "$(GREEN)OK$(RESET)\n"

status:
	@echo "$(GREEN)Container status:$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) ps
	@echo "$(GREEN)\nDocker images:$(RESET)"
	@docker ps
	@echo "$(GREEN)\nVolumes:$(RESET)"
	@docker volume ls
	@echo "$(GREEN)\nNetworks:$(RESET)"
	@docker network ls

logs:
	@echo "$(GREEN)Container logs:$(RESET)"
	@docker-compose -f $(COMPOSE_FILE) logs

help:
	@echo "$(GREEN)Available commands:$(RESET)"
	@echo "  make setup         - Create necessary directories"
	@echo "  make build         - Build Docker images"
	@echo "  make up            - Start containers"
	@echo "  make down          - Stop containers"
	@echo "  make clean         - Clean up Docker resources (except volumes)"
	@echo "  make fclean        - Remove everything including volumes and data"
	@echo "  make re            - Rebuild everything from scratch"
	@echo "  make test-volumes  - Test volume persistence"
	@echo "  make status        - Show container status"
	@echo "  make logs          - Show container logs"

.PHONY: all setup build up down clean fclean re status logs help test-volumes