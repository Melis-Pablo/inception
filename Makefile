# Variables
NAME = inception
DOCKER_COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/$(USER)/data
USER ?= $(shell whoami)

# Colors for pretty output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
RESET = \033[0m

# Basic commands
all: setup up

# Create necessary directories and setup environment
# Enhanced setup target
setup:
	@printf "$(GREEN)Creating data directories...$(RESET)\n"
	@if [ ! -d "$(DATA_PATH)" ]; then \
		sudo mkdir -p $(DATA_PATH); \
		sudo chown $(USER):$(USER) $(DATA_PATH); \
	fi
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@printf "$(YELLOW)Setting up permissions...$(RESET)\n"
	@sudo chmod 755 $(DATA_PATH)/mariadb
	@sudo chmod 755 $(DATA_PATH)/wordpress
	@sudo chown -R $(USER):$(USER) $(DATA_PATH)/mariadb
	@sudo chown -R $(USER):$(USER) $(DATA_PATH)/wordpress
	@printf "$(GREEN)Directory setup complete!$(RESET)\n"
# =================================================================================================
# setup:
# 	@printf "$(GREEN)Creating data directories...$(RESET)\n"
# 	@mkdir -p $(DATA_PATH)/mariadb
# 	@mkdir -p $(DATA_PATH)/wordpress
# =================================================================================================

# Build and start containers
up: check-volumes
	@printf "$(GREEN)Starting containers...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up --build -d

# Stop containers
down:
	@printf "$(RED)Stopping $(NAME)...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down

# Clean everything: containers, networks, images, and volumes
clean: down
	@printf "$(RED)Cleaning $(NAME)...$(RESET)\n"
	@docker system prune -a --force
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true

# Clean everything and remove data directories
fclean: clean
	@printf "$(RED)Full cleaning $(NAME)...$(RESET)\n"
	@sudo rm -rf $(DATA_PATH)

# Restart containers
re: down up

# Add a volume test target
test-volumes: up
	@printf "$(YELLOW)Testing volume persistence...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) ps | grep -q "Up" || \
		(printf "$(RED)Containers are not running!$(RESET)\n" && exit 1)
	@printf "Testing MariaDB volume..."
	@test -f $(DATA_PATH)/mariadb/mysql/user.MYD || \
		(printf "$(RED)MariaDB data not found!$(RESET)\n" && exit 1)
	@printf "$(GREEN)OK$(RESET)\n"
	@printf "Testing WordPress volume..."
	@test -f $(DATA_PATH)/wordpress/wp-config.php || \
		(printf "$(RED)WordPress data not found!$(RESET)\n" && exit 1)
	@printf "$(GREEN)OK$(RESET)\n"

# Add a volume cleanup target
clean-volumes:
	@printf "$(YELLOW)Cleaning volumes...$(RESET)\n"
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@printf "$(GREEN)Volumes cleaned!$(RESET)\n"

# Show container status
status:
	@docker ps
	@echo "\nVolumes:"
	@docker volume ls
	@echo "\nNetworks:"
	@docker network ls

# Add a volume check target
check-volumes:
	@if [ ! -d "$(DATA_PATH)/mariadb" ] || [ ! -d "$(DATA_PATH)/wordpress" ]; then \
		printf "$(RED)Volumes not set up. Running setup...$(RESET)\n" && \
		$(MAKE) setup; \
	fi

# Add to your .PHONY list
.PHONY: all setup up down clean fclean re status test-volumes clean-volumes check-volumes