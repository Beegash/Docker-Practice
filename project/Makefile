NAME = inception
SSL_DIR = srcs/requirements/nginx/conf/ssl
SSL_CERT = $(SSL_DIR)/server.crt
SSL_KEY = $(SSL_DIR)/server.key

all: ssl
	@printf "=================================================\n"
	@printf "Starting ${NAME} project...\n"
	@printf "Building Docker images and starting containers\n"
	@printf "Services: NGINX, MariaDB, WordPress\n"
	@printf "=================================================\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build
	@printf "=================================================\n"
	@printf "Services are starting up!\n"
	@printf "Access WordPress at: https://iozmen.42.fr\n"
	@printf "=================================================\n"

ssl:
	@printf "=================================================\n"
	@printf "Checking SSL certificates...\n"
	@printf "=================================================\n"
	@if [ ! -d "$(SSL_DIR)" ]; then \
		printf "Creating SSL directory...\n"; \
		mkdir -p "$(SSL_DIR)"; \
	fi
	@if [ ! -f "$(SSL_CERT)" ] || [ ! -f "$(SSL_KEY)" ]; then \
		printf "SSL certificates not found!\n"; \
		printf "Generating self-signed SSL certificate...\n"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout "$(SSL_KEY)" \
			-out "$(SSL_CERT)" \
			-subj "/C=TR/ST=Istanbul/L=Istanbul/O=42/OU=42Istanbul/CN=iozmen.42.fr"; \
		printf "SSL certificates created successfully!\n"; \
	else \
		printf "SSL certificates already exist.\n"; \
	fi
	@printf "=================================================\n"

down:
	@printf "=================================================\n"
	@printf "Stopping ${NAME} containers...\n"
	@printf "Containers will be stopped but volumes preserved\n"
	@printf "=================================================\n"
	@docker-compose -f srcs/docker-compose.yml down

clean: down
	@printf "=================================================\n"
	@printf "Cleaning up ${NAME} Docker resources...\n"
	@printf "Removing unused images, containers, networks\n"
	@printf "Note: This will prompt for confirmation\n"
	@printf "=================================================\n"
	@docker system prune -a

fclean:
	@printf "=================================================\n"
	@printf "WARNING: Complete Docker cleanup starting!\n"
	@printf "This will remove ALL Docker resources:\n"
	@printf " * All containers (running and stopped)\n"
	@printf " * All images, volumes, and networks\n"
	@printf " * All cached data\n"
	@printf "=================================================\n"
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@printf "=================================================\n"
	@printf "Complete cleanup finished!\n"
	@printf "=================================================\n"

clean-data:
	@printf "=================================================\n"
	@printf "Cleaning persistent data directories...\n"
	@printf "This will remove all database and WordPress data\n"
	@printf "=================================================\n"
	@docker-compose -f srcs/docker-compose.yml down -v 2>/dev/null || true
	@printf "Removing bind mount directories...\n"
	@sudo sh -c 'rm -rf /home/${USER}/data/mariadb/* /home/${USER}/data/mariadb/.[!.]* 2>/dev/null' || true
	@sudo sh -c 'rm -rf /home/${USER}/data/wordpress/* /home/${USER}/data/wordpress/.[!.]* 2>/dev/null' || true
	@printf "=================================================\n"
	@printf "All persistent data cleaned successfully!\n"
	@printf "=================================================\n"

clean-all: fclean clean-data
	@printf "=================================================\n"
	@printf "Complete cleanup finished!\n"
	@printf "All Docker resources and data removed.\n"
	@printf "=================================================\n"

re:	clean all

.PHONY	: all build down re clean fclean clean-data clean-all ssl
